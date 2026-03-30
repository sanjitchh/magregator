// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/INetworkDeployments.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

contract SepoliaDeployments is INetworkDeployments {
    uint256 constant CHAIN_ID = 11155111;

    // Fill these addresses after deploying upgradeable router and adapters on Sepolia.
    address constant ROUTER = 0x009B03c9DCc4B54022188207ca17fF3303D6055F;
    address constant FEE_VAULT = 0x0E0BCF47459958625B49d4a6daD03301A6480BB5;
    address constant UNISWAP_V2_ADAPTER = address(0);
    // Current UniswapV3 implementation after Sepolia upgrade: 0xc4446028922a1b612a009DFA258eD309438dfcc5.
    address constant UNISWAP_V3_ADAPTER = 0x7caF364caA220D606cd68Ca9960DE4e05cb27158;
    address constant SUSHI_V3_ADAPTER = 0x6286C48d42DC5D130D39f6B1e12bfC4cd2d3c77e;
    address constant PANCAKE_V3_ADAPTER = 0xBbb32C5436889d34F92bCEeB4805D60af3952B5d;
    address constant KURU_ADAPTER = address(0);
    address constant KYBER_ELASTIC_ADAPTER = address(0);
    address constant UNISWAP_V4_ADAPTER = address(0);
    address constant WNATIVE_ADAPTER = 0x6d19D2B066035200AAEF1895942D9aF7B6FAd1cF;

    function getChainId() public pure override returns (uint256) {
        return CHAIN_ID;
    }

    function getNetworkName() public pure override returns (string memory) {
        return "Ethereum Sepolia";
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

    function getSushiV3Adapter() public pure override returns (address) {
        return SUSHI_V3_ADAPTER;
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
        if (SUSHI_V3_ADAPTER != address(0)) count++;
        if (PANCAKE_V3_ADAPTER != address(0)) count++;
        if (KURU_ADAPTER != address(0)) count++;
        if (KYBER_ELASTIC_ADAPTER != address(0)) count++;
        if (UNISWAP_V4_ADAPTER != address(0)) count++;
        if (WNATIVE_ADAPTER != address(0)) count++;

        address[] memory adapters = new address[](count);
        uint256 i;

        if (UNISWAP_V3_ADAPTER != address(0)) adapters[i++] = UNISWAP_V3_ADAPTER;
        if (SUSHI_V3_ADAPTER != address(0)) adapters[i++] = SUSHI_V3_ADAPTER;
        if (PANCAKE_V3_ADAPTER != address(0)) adapters[i++] = PANCAKE_V3_ADAPTER;
        if (KURU_ADAPTER != address(0)) adapters[i++] = KURU_ADAPTER;
        if (KYBER_ELASTIC_ADAPTER != address(0)) adapters[i++] = KYBER_ELASTIC_ADAPTER;
        if (UNISWAP_V4_ADAPTER != address(0)) adapters[i++] = UNISWAP_V4_ADAPTER;
        if (WNATIVE_ADAPTER != address(0)) adapters[i++] = WNATIVE_ADAPTER;

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
