// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolId} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/libraries/CurrencyLibrary.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";

import {OptionManager} from "src/OptionManager.sol";
import {Sneed} from "src/Sneed.sol";
import {HookTest} from "../utils/HookTest.sol";
import {Counter} from "src/Counter.sol";
import {CounterImplementation} from "test/implementation/CounterImplementation.sol";
import {Kahjit} from "src/kahjit/Kahjit.sol";

contract Hookers is HookTest, Deployers {
    using PoolId for IPoolManager.PoolKey;
    using CurrencyLibrary for Currency;

    Counter counter = Counter(address(uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG)));

    OptionManager optionManager;
    Sneed sneed;
    IPoolManager.PoolKey poolKey;
    bytes32 poolId;

    Kahjit kahjit;

    function setUp() public {
        // creates the pool manager, test tokens, and other utility routers
        HookTest.initHookTestEnv();

        // testing environment requires our contract to override `validateHookAddress`
        // well do that via the Implementation contract to avoid deploying the override with the production contract
        CounterImplementation impl = new CounterImplementation(manager, counter);
        etchHook(address(impl), address(counter));

        // Create the pool
        poolKey = IPoolManager.PoolKey(
            Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, IHooks(counter)
        );
        poolId = PoolId.toId(poolKey);
        manager.initialize(poolKey, SQRT_RATIO_1_1);

        // Provide liquidity to the pool
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-60, 60, 10 ether));
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-120, 120, 10 ether));
        modifyPositionRouter.modifyPosition(
            poolKey, IPoolManager.ModifyPositionParams(TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10 ether)
        );

        kahjit = new Kahjit();
    }

    function testBuyOptions() public {
        uint256 amount = 1 ether;
        uint64 strike = 1 ether * 1.3;
        uint64 expiry = uint64(block.timestamp + 7 days);
        uint64 price = 1000;
        uint256 amountBought = kahjit.buyOptions(address(this), amount, strike, expiry, price, true);
        assertEq(amountBought, amount);
    }

    function testSellOptions() public {
        uint256 amount = 1 ether;
        uint64 strike = 1 ether * 1.3;
        uint64 expiry = uint64(block.timestamp + 7 days);
        uint64 price = 1000;
        kahjit.buyOptions(address(this), amount, strike, expiry, price, true);
        uint256 amountBought = kahjit.sellOptions(0);
        assertEq(amountBought, amount);
    }
}
