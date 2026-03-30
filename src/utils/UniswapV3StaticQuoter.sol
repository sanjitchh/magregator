// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

interface IStaticQuoteV3Pool {
    function liquidity() external view returns (uint128);
    function fee() external view returns (uint24);
    function slot0() external view returns (uint160, int24, uint16, uint16, uint16, uint32, bool);
}

contract UniswapV3StaticQuoter {
    uint256 private constant Q96 = 2 ** 96;
    uint256 private constant FEE_DENOMINATOR = 1_000_000;

    function quote(address pool, bool zeroForOne, int256 amountIn, uint160)
        external
        view
        returns (int256 amount0, int256 amount1)
    {
        if (amountIn <= 0) {
            return (0, 0);
        }

        uint256 inAmount = uint256(amountIn);
        uint256 feePips = IStaticQuoteV3Pool(pool).fee();
        if (feePips >= FEE_DENOMINATOR) {
            return (0, 0);
        }

        uint256 amountInAfterFee = Math.mulDiv(inAmount, FEE_DENOMINATOR - feePips, FEE_DENOMINATOR);
        if (amountInAfterFee == 0) {
            return (0, 0);
        }

        uint256 liq = uint256(IStaticQuoteV3Pool(pool).liquidity());
        if (liq == 0) {
            return (0, 0);
        }

        (uint160 sqrtPriceX96,,,,,,) = IStaticQuoteV3Pool(pool).slot0();
        if (sqrtPriceX96 == 0) {
            return (0, 0);
        }

        uint256 sqrtP = uint256(sqrtPriceX96);
        uint256 reserve0 = Math.mulDiv(liq, Q96, sqrtP);
        uint256 reserve1 = Math.mulDiv(liq, sqrtP, Q96);
        if (reserve0 == 0 || reserve1 == 0) {
            return (0, 0);
        }

        uint256 out;
        if (zeroForOne) {
            out = Math.mulDiv(reserve1, amountInAfterFee, reserve0 + amountInAfterFee);
            if (out > reserve1) out = reserve1;
            amount0 = int256(inAmount);
            amount1 = -int256(out);
        } else {
            out = Math.mulDiv(reserve0, amountInAfterFee, reserve1 + amountInAfterFee);
            if (out > reserve0) out = reserve0;
            amount0 = -int256(out);
            amount1 = int256(inAmount);
        }
    }
}
