// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/INetworkDeployments.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

contract EthereumDeployments is INetworkDeployments {
    uint256 constant CHAIN_ID = 1;

    // Fill these addresses after deploying the router and adapters on Ethereum mainnet.
    // Current UniswapV3StaticQuoter deployment: 0xC05BE9059Ba251Ee7e2B68D652fF0AF3E3279817.
    address constant ROUTER = 0xEa8674550BbEDF3502C7C20206608a40647F7654;
    address constant FEE_VAULT = 0x8d3BAA635Ab51D9adD8Ef054cAF006deec5AA9E4;
    address constant UNISWAP_V2_ADAPTER = address(0);
    address constant UNISWAP_V3_ADAPTER = address(0);
    address constant SUSHI_V3_ADAPTER = 0xBf029a16F231233ebD0325C40f25A60dFcc40E8a;
    address constant PANCAKE_V3_ADAPTER = 0x688a18be02a0EaFC41EBc5d3bbDd09554A5Fb5f3;
    address constant KURU_ADAPTER = address(0);
    address constant KYBER_ELASTIC_ADAPTER = address(0);
    address constant UNISWAP_V4_ADAPTER = address(0);
    address constant WNATIVE_ADAPTER = address(0);

    function getChainId() public pure override returns (uint256) {
        return CHAIN_ID;
    }

    function getNetworkName() public pure override returns (string memory) {
        return "Ethereum Mainnet";
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
        if (UNISWAP_V2_ADAPTER != address(0)) count++;
        if (UNISWAP_V3_ADAPTER != address(0)) count++;
        if (SUSHI_V3_ADAPTER != address(0)) count++;
        if (PANCAKE_V3_ADAPTER != address(0)) count++;
        if (KURU_ADAPTER != address(0)) count++;
        if (KYBER_ELASTIC_ADAPTER != address(0)) count++;
        if (UNISWAP_V4_ADAPTER != address(0)) count++;
        if (WNATIVE_ADAPTER != address(0)) count++;

        address[] memory adapters = new address[](count);
        uint256 i;

        if (UNISWAP_V2_ADAPTER != address(0)) adapters[i++] = UNISWAP_V2_ADAPTER;
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
        address[] memory tokens = new address[](5);
        tokens[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
        tokens[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
        tokens[2] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
        tokens[3] = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
        tokens[4] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599; // WBTC
        return tokens;
    }

    function getUniswapV4Adapter() public pure override returns (address) {
        return UNISWAP_V4_ADAPTER;
    }

    function getWhitelistedUniswapV4Pools() public pure override returns (PoolKey[] memory) {
        return new PoolKey[](0);
    }
}
