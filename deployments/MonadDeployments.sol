// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/INetworkDeployments.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

contract MonadDeployments is INetworkDeployments {
    uint256 constant CHAIN_ID = 143;

    // Fill these addresses after deploying the router and adapters on Monad.
    address constant ROUTER = 0xC1AE182eEd95cb9215B140db4aFD79c9E86f51C7;
    address constant UNISWAP_V3_ADAPTER = 0x7694078AeC18DaE9238dAb946945BC2fE20d7322;
    address constant KYBER_ELASTIC_ADAPTER = address(0);
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
        uint256 count;
        if (UNISWAP_V3_ADAPTER != address(0)) count++;
        if (KYBER_ELASTIC_ADAPTER != address(0)) count++;

        address[] memory adapters = new address[](count);
        uint256 i;

        if (UNISWAP_V3_ADAPTER != address(0)) {
            adapters[i] = UNISWAP_V3_ADAPTER;
            i++;
        }
        if (KYBER_ELASTIC_ADAPTER != address(0)) {
            adapters[i] = KYBER_ELASTIC_ADAPTER;
        }

        return adapters;
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
