// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./UniswapV3AdapterBase.sol";

contract SushiV3Adapter is UniswapV3AdapterBase {
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        uint256 _swapGasEstimate,
        uint256 _quoterGasLimit,
        address _quoter,
        address _factory,
        uint24[] memory _defaultFees,
        address _initialMaintainer
    ) external initializer {
        __UniswapV3AdapterBase_init(
            _name,
            _swapGasEstimate,
            _quoterGasLimit,
            _quoter,
            _factory,
            _defaultFees,
            _initialMaintainer
        );
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        address pool = _validateSwapCallback(data);

        if (amount0Delta > 0) {
            IERC20(IUniV3Pool(pool).token0()).transfer(pool, uint256(amount0Delta));
        } else if (amount1Delta > 0) {
            IERC20(IUniV3Pool(pool).token1()).transfer(pool, uint256(amount1Delta));
        }
    }
}
