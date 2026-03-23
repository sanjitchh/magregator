// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../interface/IERC20.sol";
import "../lib/SafeERC20.sol";
import "../MoksaAdapter.sol";

struct QParams {
    address tokenIn;
    address tokenOut;
    int256 amountIn;
    uint24 fee;
}

interface IUniV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function liquidity() external view returns (uint128);
}

interface IUniV3Quoter {
    function quoteExactInputSingle(
        QParams memory params
    ) external view returns (uint256);

    function quote(
        address,
        bool,
        int256,
        uint160
    ) external view returns (int256, int256);
}

abstract contract UniswapV3likeAdapter is MoksaAdapter {
    using SafeERC20 for IERC20;

    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint256 internal constant QUOTE_SAFETY_DIVISOR = 10_000;
    uint256 public quoterGasLimit;
    address public quoter;

    function __UniswapV3likeAdapter_init(
        string memory _name,
        uint256 _swapGasEstimate,
        address _quoter,
        uint256 _quoterGasLimit,
        address _initialMaintainer
    ) internal onlyInitializing {
        __MoksaAdapter_init(_name, _swapGasEstimate, _initialMaintainer);
        setQuoterGasLimit(_quoterGasLimit);
        setQuoter(_quoter);
    }

    function setQuoter(address newQuoter) public onlyMaintainer {
        quoter = newQuoter;
    }

    function setQuoterGasLimit(uint256 newLimit) public onlyMaintainer {
        require(newLimit != 0, "queryGasLimit can't be zero");
        quoterGasLimit = newLimit;
    }

    function getQuoteForPool(
        address pool,
        int256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256) {
        QParams memory params;
        params.amountIn = amountIn;
        params.tokenIn = tokenIn;
        params.tokenOut = tokenOut;
        return getQuoteForPool(pool, params);
    }

    function _query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) internal view override returns (uint256 quote) {
        QParams memory params = getQParams(_amountIn, _tokenIn, _tokenOut);
        quote = getQuoteForBestPool(params);
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        address _to
    ) internal override {
        QParams memory params = getQParams(_amountIn, _tokenIn, _tokenOut);
        uint256 amountOut = _underlyingSwap(params, new bytes(0));
        require(amountOut >= _amountOut, "Insufficient amountOut");
        _returnTo(_tokenOut, amountOut, _to);
    }

    function getQParams(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) internal pure returns (QParams memory params) {
        params = QParams({ 
            amountIn: int256(amountIn), 
            tokenIn: tokenIn, 
            tokenOut: tokenOut, 
            fee: 0 
        });
    }

    function _underlyingSwap(
        QParams memory params, 
        bytes memory callbackData
    ) internal virtual returns (uint256) {
        address pool = getBestPool(params.tokenIn, params.tokenOut);
        require(pool != address(0), "Pool not found");
        if (callbackData.length == 0) {
            callbackData = _encodeSwapCallbackData(params.tokenIn, params.tokenOut, pool);
        }
        (bool zeroForOne, uint160 priceLimit) = getZeroOneAndSqrtPriceLimitX96(
            params.tokenIn, 
            params.tokenOut
        );
        (int256 amount0, int256 amount1) = IUniV3Pool(pool).swap(
            address(this),
            zeroForOne,
            int256(params.amountIn),
            priceLimit,
            callbackData
        );
        return zeroForOne ? uint256(-amount1) : uint256(-amount0);
    }

    function _encodeSwapCallbackData(
        address tokenIn,
        address tokenOut,
        address pool
    ) internal pure returns (bytes memory) {
        return abi.encode(tokenIn, tokenOut, pool);
    }

    function _validateSwapCallback(bytes calldata callbackData) internal view returns (address pool) {
        require(callbackData.length == 96, "Invalid callback data");

        (address tokenIn, address tokenOut, address expectedPool) = abi.decode(
            callbackData,
            (address, address, address)
        );

        require(expectedPool != address(0), "Invalid callback pool");
        require(_isValidCallbackPool(tokenIn, tokenOut, expectedPool), "Invalid callback pool");
        require(msg.sender == expectedPool, "Invalid callback caller");

        return expectedPool;
    }

    function getQuoteForBestPool(
        QParams memory params
    ) internal view returns (uint256 quote) {
        address bestPool = getBestPool(params.tokenIn, params.tokenOut);
        if (bestPool != address(0)) quote = getQuoteForPool(bestPool, params);
    }

    function getBestPool(
        address token0, 
        address token1
    ) internal view virtual returns (address mostLiquid);

    function _isValidCallbackPool(
        address tokenIn,
        address tokenOut,
        address pool
    ) internal view virtual returns (bool);
    
    function getQuoteForPool(
        address pool, 
        QParams memory params
    ) internal view returns (uint256) {
        (bool zeroForOne, uint160 priceLimit) = getZeroOneAndSqrtPriceLimitX96(
            params.tokenIn, 
            params.tokenOut
        );
        (int256 amount0, int256 amount1) = getQuoteSafe(
            pool,
            zeroForOne,
            params.amountIn,
            priceLimit
        );
        uint256 rawQuote = zeroForOne ? uint256(-amount1) : uint256(-amount0);
        return _applyQuoteSafetyMargin(rawQuote);
    }

    function _applyQuoteSafetyMargin(uint256 rawQuote) internal pure returns (uint256) {
        if (rawQuote == 0) {
            return 0;
        }

        uint256 margin = rawQuote / QUOTE_SAFETY_DIVISOR;
        if (margin == 0) {
            margin = 1;
        }

        return rawQuote > margin ? rawQuote - margin : 0;
    }

    function getQuoteSafe(
        address pool, 
        bool zeroForOne,
        int256 amountIn,
        uint160 priceLimit
    ) internal view returns (int256 amount0, int256 amount1) {
        bytes memory calldata_ = abi.encodeWithSignature(
            "quote(address,bool,int256,uint160)",
            pool,
            zeroForOne,
            amountIn,
            priceLimit
        );
        (bool success, bytes memory data) = staticCallQuoterRaw(calldata_);
        if (success)
            (amount0, amount1) = abi.decode(data, (int256, int256));
    }

    function staticCallQuoterRaw(
        bytes memory calldata_
    ) internal view returns (bool success, bytes memory data) {
        (success, data) = quoter.staticcall{gas: quoterGasLimit}(calldata_);
    }

    function getZeroOneAndSqrtPriceLimitX96(address tokenIn, address tokenOut)
        internal
        pure
        returns (bool zeroForOne, uint160 sqrtPriceLimitX96)
    {
        zeroForOne = tokenIn < tokenOut;
        sqrtPriceLimitX96 = zeroForOne ? MIN_SQRT_RATIO+1 : MAX_SQRT_RATIO-1;
    }
}
