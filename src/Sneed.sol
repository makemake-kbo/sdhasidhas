// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {Currency} from "@uniswap/v4-core/contracts/libraries/CurrencyLibrary.sol";
import {PoolId} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {OptionManager} from "src/OptionManager.sol";

import "./kahjit/IKahjit.sol";
import "./AggregatorV3Interface.sol";
import "./OptionChoice.sol";
import "./IERC20.sol";

error InexistentPosition();

contract Sneed is BaseHook, OptionChoice {
    using PoolId for IPoolManager.PoolKey;

    bool private isAmount0Eth = false;
    bool private gonnaBeEth = false;
    bool private hasActiveOption = false;
    uint256 private currentPositionId = 0;
    uint256 private currentActiveContracts = 0;

    int256 ethBalanceBefore;
    uint256 ethRemainder;

    address private kahjitAddress;
    address private chainlinkAddress;

    constructor(IPoolManager _poolManager, address _kahjitAddress, bool _gonnaBeEth, address _chainlinkAddress) BaseHook(_poolManager) {
        kahjitAddress = _kahjitAddress;
        gonnaBeEth = _gonnaBeEth;
        chainlinkAddress = _chainlinkAddress;
    }

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: true,
            afterInitialize: false,
            beforeModifyPosition: true,
            afterModifyPosition: true,
            beforeSwap: false,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: true
        });
    }

    function beforeInitialize(address sender, IPoolManager.PoolKey calldata key, uint160 sqrtPriceX96)
        external
        override
        returns (bytes4)
    {
        // TODO: fix this shit !
        // if (key.currency0 == Currency.wrap(address(0))) {
        //     isAmount0Eth = true;
        // }
        if (gonnaBeEth) {
            isAmount0Eth = true;
        }

        return BaseHook.beforeSwap.selector;
    }

    function afterDonate(address sender, IPoolManager.PoolKey calldata key, uint256 amount0, uint256 amount1)
        external
        override
        returns (bytes4)
    {
        _checkActive();

        // Get how much eth we're depositing so we can get how much contracts we need to buy
        uint256 contractAmount;
        if (isAmount0Eth) {
            contractAmount = amount0;
        } else {
            contractAmount = amount1;
        }

        // get how much eth we're depositing, since its going to be whole we need to truncate the decimals
        contractAmount = contractAmount / 1e18;

        (,int256 answer,,,) = AggregatorV3Interface(chainlinkAddress).latestRoundData();

        IKahjit(kahjitAddress).buyOptions(
            contractAmount,
            uint64(whichStrike(uint256(answer))),
            uint64((block.timestamp + 30 days)),
            10,
            true
        );

        return BaseHook.beforeSwap.selector;
    }

    function beforeModifyPosition(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params,
        BalanceDelta delta
    ) external returns (bytes4) {
        ethBalanceBefore = int256(IERC20(Currency.unwrap(key.currency0)).balanceOf(address(this)));

        return BaseHook.beforeSwap.selector;
    }

    function afterModifyPosition(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params,
        BalanceDelta delta
    ) external override returns (bytes4) {
        _checkActive();

        int256 ethBalanceDelta = int256(IERC20(Currency.unwrap(key.currency0)).balanceOf(address(this))) - ethBalanceBefore;

        // Implying we have 18 decimals
        // We have to buy whole eth options sadge 
        ethRemainder = ethRemainder + uint256(ethBalanceDelta) % 1e18;
        ethBalanceDelta = ethBalanceDelta / 1e18;

        // add 1 to the balancedelta if 1 eth in the remainder
        if (ethRemainder >= 1e18) {
            ethBalanceDelta = ethBalanceDelta + 1;
            ethRemainder = ethRemainder - 1e18;
        }

        (,int256 answer,,,) = AggregatorV3Interface(chainlinkAddress).latestRoundData();

        // if delta is positive, buy options
        if (ethBalanceDelta > 0) {

            IKahjit(kahjitAddress).buyOptions(
                uint256(ethBalanceDelta),
                uint64(whichStrike(uint256(answer))),
                uint64((block.timestamp + 30 days)),
                10,
                true
            );
        } else {
            // if delta is negative, sell options
            IKahjit(kahjitAddress).sellOptions(
                uint256(ethBalanceDelta),
                uint64(whichStrike(uint256(answer))),
                uint64((block.timestamp + 30 days)),
                10,
                true
            );
        }

        return BaseHook.beforeSwap.selector;
    }

    function _checkActive() internal {
        if (currentPositionId == 0) {
            revert InexistentPosition();
        }

        if (IKahjit(kahjitAddress).isExpired()) {
            hasActiveOption = false;
        }
    }
}
