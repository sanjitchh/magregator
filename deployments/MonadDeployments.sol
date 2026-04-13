// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/INetworkDeployments.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

contract MonadDeployments is INetworkDeployments {
    uint256 constant CHAIN_ID = 143;

    // Fill these addresses after deploying the router and adapters on Monad.
    address constant ROUTER = 0x09e5c9eE065978F6a9a2F07CF8aAf2B449D3318e;
    // Current FeeVault implementation after Monad deploy: 0x0468c436055eD301f227178e17d2a084Ba526E1b.
    address constant FEE_VAULT = 0x2cb1247AF8313e36FA6ee071B1Ec815d5d4ce904;
    address constant STAKING = address(0);
    address constant UNISWAP_V2_ADAPTER = address(0);
    // Current UniswapV3 implementation after Monad redeploy: 0x4433CDF3275f6C557c4969bD325729ec3563Ed68.
    address constant UNISWAP_V3_ADAPTER = 0xbCC54C8Ca1363C004A80944ff0aEf0d3356E0efC;
    address constant SUSHI_V3_ADAPTER = address(0);
    // Current PancakeV3 implementation after Monad redeploy: 0xF10a4b96A63C4DED70F235B8171fD55A9Cf3871E.
    address constant PANCAKE_V3_ADAPTER = 0x60aFAE2FFF02cAB90Afa2a8fE025Dcb1FC7d0F69;
    // Current Kuru implementation after Monad redeploy: 0x764535e505aF9fCEB2725CEB5f124797072E8AF0.
    address constant KURU_ADAPTER = 0x5a1B8BF59027b5C24A00d45a5676E5deb94D9A0f;
    address constant KYBER_ELASTIC_ADAPTER = address(0);
    address constant UNISWAP_V4_ADAPTER = address(0);
    // Current WNative implementation after Monad redeploy: 0x2dfE28eebf0C6B60c080ab52c0c573bBc94bdb6d.
    address constant WNATIVE_ADAPTER = 0x4fbEEa204Ef8E8163e8da2Aff24451E83ecA6d6E;

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

    function getStaking() public pure override returns (address) {
        return STAKING;
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
        if (WNATIVE_ADAPTER != address(0)) count++;

        address[] memory adapters = new address[](count);
        uint256 i;

        if (UNISWAP_V3_ADAPTER != address(0)) {
            adapters[i] = UNISWAP_V3_ADAPTER;
            i++;
        }
        if (SUSHI_V3_ADAPTER != address(0)) {
            adapters[i] = SUSHI_V3_ADAPTER;
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
        address[] memory tokens = new address[](3);
        tokens[0] = 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A; // WMON
        tokens[1] = 0x754704Bc059F8C67012fEd69BC8A327a5aafb603; // USDC
        tokens[2] = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a; // aUSD
        return tokens;
    }

    function getUniswapV4Adapter() public pure override returns (address) {
        return UNISWAP_V4_ADAPTER;
    }

    function getWhitelistedUniswapV4Pools() public pure override returns (PoolKey[] memory) {
        return new PoolKey[](0);
    }
}
