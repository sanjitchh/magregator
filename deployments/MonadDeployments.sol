// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/INetworkDeployments.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

contract MonadDeployments is INetworkDeployments {
    uint256 constant CHAIN_ID = 143;

    // Fill these addresses after deploying the router and adapters on Monad.
    address constant ROUTER = 0x09e5c9eE065978F6a9a2F07CF8aAf2B449D3318e;
    address constant FEE_VAULT = address(0);
    address constant UNISWAP_V2_ADAPTER = address(0);
    address constant UNISWAP_V3_ADAPTER = 0x6405e08499364968321AaAD480da88DC4283e943;
    address constant PANCAKE_V3_ADAPTER = 0x7caF364caA220D606cd68Ca9960DE4e05cb27158;
    address constant KURU_ADAPTER = 0x8F88Da856160b6753063F90d7180B800f9E67ee0;
    address constant KYBER_ELASTIC_ADAPTER = address(0);
    address constant UNISWAP_V4_ADAPTER = address(0);
    address constant WNATIVE_ADAPTER = 0xEe50F0611F201A255e4852e44EBCcBd0cB86bF02;

    function getChainId() public pure override returns (uint256) {
        return CHAIN_ID;
    }

    function getNetworkName() public pure override returns (string memory) {
        return "Monad";
    }

    function getRouter() public pure override returns (address) {
        return ROUTER;
    }

    function getFeeVault() public pure override returns (address) {
        return FEE_VAULT;
    }

    function getUniswapV2Adapter() public pure override returns (address) {
        return UNISWAP_V2_ADAPTER;
    }

    function getUniswapV3Adapter() public pure override returns (address) {
        return UNISWAP_V3_ADAPTER;
    }

    function getPancakeV3Adapter() public pure override returns (address) {
        return PANCAKE_V3_ADAPTER;
    }

    function getKyberElasticAdapter() public pure override returns (address) {
        return KYBER_ELASTIC_ADAPTER;
    }

    function getWNativeAdapter() public pure override returns (address) {
        return WNATIVE_ADAPTER;
    }

    function getKuruAdapter() public pure override returns (address) {
        return KURU_ADAPTER;
    }

    function getWhitelistedAdapters() public pure override returns (address[] memory) {
        uint256 count;
        if (UNISWAP_V3_ADAPTER != address(0)) count++;
        if (PANCAKE_V3_ADAPTER != address(0)) count++;
        if (KURU_ADAPTER != address(0)) count++;
        if (KYBER_ELASTIC_ADAPTER != address(0)) count++;
        if (WNATIVE_ADAPTER != address(0)) count++;

        address[] memory adapters = new address[](count);
        uint256 i;

        if (UNISWAP_V3_ADAPTER != address(0)) {
            adapters[i] = UNISWAP_V3_ADAPTER;
            i++;
        }
        if (PANCAKE_V3_ADAPTER != address(0)) {
            adapters[i] = PANCAKE_V3_ADAPTER;
            i++;
        }
        if (KURU_ADAPTER != address(0)) {
            adapters[i] = KURU_ADAPTER;
            i++;
        }
        if (KYBER_ELASTIC_ADAPTER != address(0)) {
            adapters[i] = KYBER_ELASTIC_ADAPTER;
            i++;
        }
        if (WNATIVE_ADAPTER != address(0)) {
            adapters[i] = WNATIVE_ADAPTER;
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
