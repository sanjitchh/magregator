// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUniswapV4StaticQuoter} from "../interface/IUniswapV4StaticQuoter.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {TickBitmap} from "@uniswap/v4-core/src/libraries/TickBitmap.sol";
import {BitMath} from "@uniswap/v4-core/src/libraries/BitMath.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {SwapMath} from "@uniswap/v4-core/src/libraries/SwapMath.sol";
import {ProtocolFeeLibrary} from "@uniswap/v4-core/src/libraries/ProtocolFeeLibrary.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {LiquidityMath} from "@uniswap/v4-core/src/libraries/LiquidityMath.sol";

contract UniswapV4StaticQuoter is IUniswapV4StaticQuoter {
    using PoolIdLibrary for PoolKey;
    using ProtocolFeeLibrary for uint24;
    using LPFeeLibrary for uint24;

    error DynamicFeePoolUnsupported(PoolId poolId);
    error HookQuotingUnsupported(address hooks);
    error HookDataUnsupported();
    error NotEnoughLiquidity(PoolId poolId);

    IPoolManager public immutable poolManager;

    constructor(address _poolManager) {
        poolManager = IPoolManager(_poolManager);
    }

    function quoteExactInputSingle(QuoteExactInputSingleParams memory params) external view returns (uint256 amountOut) {
        if (address(params.poolKey.hooks) != address(0)) {
            revert HookQuotingUnsupported(address(params.poolKey.hooks));
        }
        if (params.hookData.length != 0) {
            revert HookDataUnsupported();
        }
        if (params.amountIn == 0) {
            return 0;
        }

        amountOut = _quoteExactInputSingle(params.poolKey, params.zeroForOne, params.amountIn, params.sqrtPriceLimitX96);
    }

    function _quoteExactInputSingle(PoolKey memory poolKey, bool zeroForOne, uint128 amountIn, uint160 sqrtPriceLimitX96)
        internal
        view
        returns (uint256 amountOut)
    {
        PoolId poolId = poolKey.toId();
        (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee) = StateLibrary.getSlot0(poolManager, poolId);
        if (sqrtPriceX96 == 0) {
            return 0;
        }

        if (lpFee.isDynamicFee()) {
            revert DynamicFeePoolUnsupported(poolId);
        }

        uint128 liquidity = StateLibrary.getLiquidity(poolManager, poolId);
        if (liquidity == 0) {
            return 0;
        }

        uint24 swapFee = protocolFee == 0
            ? lpFee
            : ProtocolFeeLibrary.calculateSwapFee(
                zeroForOne ? protocolFee.getZeroForOneFee() : protocolFee.getOneForZeroFee(), lpFee
            );

        if (sqrtPriceLimitX96 == 0) {
            sqrtPriceLimitX96 = zeroForOne ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1;
        }

        int256 amountSpecifiedRemaining = -int256(uint256(amountIn));
        int256 amountCalculated;

        while (!(amountSpecifiedRemaining == 0 || sqrtPriceX96 == sqrtPriceLimitX96)) {
            (int24 tickNext, bool initialized) =
                _nextInitializedTickWithinOneWord(poolId, tick, poolKey.tickSpacing, zeroForOne);

            if (tickNext <= TickMath.MIN_TICK) {
                tickNext = TickMath.MIN_TICK;
            }
            if (tickNext >= TickMath.MAX_TICK) {
                tickNext = TickMath.MAX_TICK;
            }

            uint160 sqrtPriceNextX96 = TickMath.getSqrtPriceAtTick(tickNext);
            uint160 sqrtPriceStartX96 = sqrtPriceX96;
            uint256 stepAmountIn;
            uint256 stepAmountOut;
            uint256 feeAmount;

            (sqrtPriceX96, stepAmountIn, stepAmountOut, feeAmount) = SwapMath.computeSwapStep(
                sqrtPriceX96,
                SwapMath.getSqrtPriceTarget(zeroForOne, sqrtPriceNextX96, sqrtPriceLimitX96),
                liquidity,
                amountSpecifiedRemaining,
                swapFee
            );

            unchecked {
                amountSpecifiedRemaining += int256(stepAmountIn + feeAmount);
                amountCalculated += int256(stepAmountOut);
            }

            if (sqrtPriceX96 == sqrtPriceNextX96) {
                if (initialized) {
                    (, int128 liquidityNet) = StateLibrary.getTickLiquidity(poolManager, poolId, tickNext);
                    if (zeroForOne) {
                        liquidityNet = -liquidityNet;
                    }
                    liquidity = LiquidityMath.addDelta(liquidity, liquidityNet);
                }

                unchecked {
                    tick = zeroForOne ? tickNext - 1 : tickNext;
                }
            } else if (sqrtPriceX96 != sqrtPriceStartX96) {
                tick = TickMath.getTickAtSqrtPrice(sqrtPriceX96);
            }
        }

        if (amountSpecifiedRemaining != 0) {
            revert NotEnoughLiquidity(poolId);
        }

        amountOut = uint256(amountCalculated);
    }

    function _nextInitializedTickWithinOneWord(PoolId poolId, int24 tick, int24 tickSpacing, bool lte)
        internal
        view
        returns (int24 next, bool initialized)
    {
        unchecked {
            int24 compressed = TickBitmap.compress(tick, tickSpacing);

            if (lte) {
                (int16 wordPos, uint8 bitPos) = TickBitmap.position(compressed);
                uint256 mask = type(uint256).max >> (uint256(type(uint8).max) - bitPos);
                uint256 masked = StateLibrary.getTickBitmap(poolManager, poolId, wordPos) & mask;

                initialized = masked != 0;
                next = initialized
                    ? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                    : (compressed - int24(uint24(bitPos))) * tickSpacing;
            } else {
                (int16 wordPos, uint8 bitPos) = TickBitmap.position(++compressed);
                uint256 mask = ~((uint256(1) << bitPos) - 1);
                uint256 masked = StateLibrary.getTickBitmap(poolManager, poolId, wordPos) & mask;

                initialized = masked != 0;
                next = initialized
                    ? (compressed + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                    : (compressed + int24(uint24(type(uint8).max - bitPos))) * tickSpacing;
            }
        }
    }
}
