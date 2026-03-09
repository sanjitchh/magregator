// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./UniswapV3AdapterBase.sol";

contract UniswapV3Adapter is UniswapV3AdapterBase {

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

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        if (amount0Delta > 0) {
            IERC20(IUniV3Pool(msg.sender).token0()).transfer(msg.sender, uint256(amount0Delta));
        } else {
            IERC20(IUniV3Pool(msg.sender).token1()).transfer(msg.sender, uint256(amount1Delta));
        }
    }
}
