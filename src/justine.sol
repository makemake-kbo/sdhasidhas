// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolId} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";

import {LyraAdapter} from "@lyrafinance/protocol/contracts/periphery/LyraAdapter.sol";

contract Justine is BaseHook {
    using PoolId for IPoolManager.PoolKey;

    bool private isAmount0Eth = false;

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
        return BaseHook.beforeSwap.selector;
    }

    function afterModifyPosition(address sender, IPoolManager.PoolKey calldata key, ModifyPositionParams.ModifyParams calldata params)
        external
        override
        returns (bytes4)
    {
        return BaseHook.beforeSwap.selector;
    }

}
