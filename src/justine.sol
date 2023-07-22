// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolId} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {Currency} from "@uniswap/v4-core/contracts/libraries/CurrencyLibrary.sol";

import "./OptionManager.sol";
import "./OptionChoice.sol";

// remapings refuse to work so we import it here enjoy 
interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract Justine is BaseHook, OptionManager {
    using PoolId for IPoolManager.PoolKey;

    bool private isAmount0Eth = false;
    bool private hasActiveOption = false;
    uint256 private currentPositionId = 0;
    uint256 private currentActiveContracts = 0;
    AggregatorV3Interface internal dataFeed;

    constructor(IPoolManager _poolManager, address _feed) BaseHook(_poolManager) {
        dataFeed = AggregatorV3Interface(
            _feed
        );
    }

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: true,
            afterInitialize: false,
            beforeModifyPosition: true,
            afterModifyPosition: false,
            beforeSwap: false,
            afterSwap: false,
            beforeDonate: true,
            afterDonate: false
        });
    }

    function beforeInitialize(address sender, IPoolManager.PoolKey calldata key, uint160 sqrtPriceX96)
        external
        override
        returns (bytes4)
    {
        if (key.currency0 == address(0)) {
            isAmount0Eth = true;
        }

        return BaseHook.beforeSwap.selector;
    }

    function beforeDonate(address sender, IPoolManager.PoolKey calldata key, uint256 amount0, uint256 amount1)
        external
        override
        returns (bytes4)
    {
        // TODO: Add a check if our option expired

        // Get how much eth we're depositing so we can get how much contracts we need to buy
        uint256 contractAmount;
        if (isAmount0Eth) {
            contractAmount = amount0;
        } else {
            contractAmount = amount1;
        }

        // get how much eth we're depositing, since its going to be whole we need to truncate the decimals
        contractAmount = contractAmount / 1e18;

        if (hasActiveOption) {
            modifyLyraPosition(currentPositionId, contractAmount);
        } else {
            uint256 _boardId = getBoardId(block.timestamp + 7 days);
            (,int256 answer,,,) = dataFeed.latestRoundData();
            uint256 _strike = whichStrike(answer, _boardId);

            currentPositionId = openNewLyraPosition(_strike, contractAmount);
            hasActiveOption = true;
        }

        return BaseHook.beforeSwap.selector;
    }

    function beforeModifyPosition(
        address sender,
        IPoolManager.PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params,
        BalanceDelta delta
    ) external override returns (bytes4) {
        // TODO: Add a check if our option expired

        return BaseHook.beforeSwap.selector;
    }
}