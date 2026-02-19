// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/INetworkDeployments.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

contract MonadDeployments is INetworkDeployments {
    uint256 constant CHAIN_ID = 10143;

    // Fill these addresses after deploying the router and adapters on Monad.
    address constant ROUTER = address(0);
    address constant UNISWAP_V4_ADAPTER = address(0);

    function getChainId() public pure override returns (uint256) {
        return CHAIN_ID;
    }

    function getNetworkName() public pure override returns (string memory) {
        return "Monad";
    }

    function getRouter() public pure override returns (address) {
        return ROUTER;
    }

    function getWhitelistedAdapters() public pure override returns (address[] memory) {
        return new address[](0);
    }

    function getWhitelistedHopTokens() public pure override returns (address[] memory) {
        return new address[](0);
    }

    function getUniswapV4Adapter() public pure override returns (address) {
        return UNISWAP_V4_ADAPTER;
    }

    function getWhitelistedUniswapV4Pools() public pure override returns (PoolKey[] memory) {
        return new PoolKey[](0);
    }
}
