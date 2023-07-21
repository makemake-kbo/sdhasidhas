// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolId} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {OptionManager} from "./OptionManager.sol"


contract Justine is BaseHook {
    using PoolId for IPoolManager.PoolKey;

    bool private isAmount0Eth = false;
    uint256 private currentPositionId = 0;
    uint256 private currentActiveContracts = 0;

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: true,
            afterInitialize: false,
            beforeModifyPosition: false,
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
        if (key.currency0 == address(0)) {
            isAmount0Eth = true;
        }

        return BaseHook.beforeSwap.selector;
    }

    function afterDonate(address sender, IPoolManager.PoolKey calldata key, uint256 amount0, uint256 amount1)
        external
        override
        returns (bytes4)
    {
        // Get how much eth we're depositing
        uint ethAmount;   
        if (isAmount0Eth) {
            ethAmount = amount0;
        } else {
            ethAmount = amount1;
        }

        // get how much eth we're depositing, since its going to be whole we need to truncate the decimals
        ethAmount = ethAmount / 1e18;

        if (hasActiveOption) {
            modifyLyraPosition(uint256 positionId, uint256 amount, uint256 collateral);
        } else {
            openNewLyraPosition(uint256 strikeId, uint256 amount)
        }

        return BaseHook.beforeSwap.selector;
    }

    function afterModifyPosition(
        address sender,
        IPoolManager.PoolKey calldata key,
        ModifyPositionParams.ModifyParams calldata params
    ) external override returns (bytes4) {

        return BaseHook.beforeSwap.selector;
    }
}
