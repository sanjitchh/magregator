// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeV3QuotePool {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function fee() external view returns (uint24);
}

contract PancakeV3StaticQuoter {
    error InvalidAmountIn();

    address public immutable quoterV2;

    constructor(address _quoterV2) {
        quoterV2 = _quoterV2;
    }

    function quote(address pool, bool zeroForOne, int256 amountIn, uint160 sqrtPriceLimitX96)
        external
        view
        returns (int256 amount0, int256 amount1)
    {
        if (amountIn <= 0) {
            revert InvalidAmountIn();
        }

        IPancakeV3QuotePool quotePool = IPancakeV3QuotePool(pool);
        address token0 = quotePool.token0();
        address token1 = quotePool.token1();

        (bool success, bytes memory data) = quoterV2.staticcall(
            abi.encodeWithSignature(
                "quoteExactInputSingle((address,address,uint256,uint24,uint160))",
                QuoteExactInputSingleParams({
                    tokenIn: zeroForOne ? token0 : token1,
                    tokenOut: zeroForOne ? token1 : token0,
                    amountIn: uint256(amountIn),
                    fee: quotePool.fee(),
                    sqrtPriceLimitX96: sqrtPriceLimitX96
                })
            )
        );

        if (!success) {
            return (0, 0);
        }

        (uint256 amountOut,,,) = abi.decode(data, (uint256, uint160, uint32, uint256));

        if (zeroForOne) {
            amount0 = amountIn;
            amount1 = -int256(amountOut);
        } else {
            amount0 = -int256(amountOut);
            amount1 = amountIn;
        }
    }

    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }
}
