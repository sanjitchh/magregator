// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SepoliaStakingDeployments {
    uint256 constant CHAIN_ID = 11155111;

    // Fill STAKING after deploying the Sepolia staking proxy.
    address constant STAKING = 0x5aD4055425dAe699B601ee563c0624bb080f3fb3;
    address constant STAKING_TOKEN = 0x3B84eF59371EA31Bd11cf2b439D6d4bC1d48E711;
    address constant REWARD_TOKEN = 0xfbA19277c8a31C341748B65D30fa96984C6b6162;
    address constant INITIAL_MAINTAINER = 0xf3C0095A26c0Ae75Aa757Fab74a740B31228f6f4;
    uint256 constant UNBONDING_PERIOD = 7 days;

    function getChainId() public pure returns (uint256) {
        return CHAIN_ID;
    }

    function getNetworkName() public pure returns (string memory) {
        return "Ethereum Sepolia";
    }

    function getStaking() public pure returns (address) {
        return STAKING;
    }

    function getStakingToken() public pure returns (address) {
        return STAKING_TOKEN;
    }

    function getRewardToken() public pure returns (address) {
        return REWARD_TOKEN;
    }

    function getInitialMaintainer() public pure returns (address) {
        return INITIAL_MAINTAINER;
    }

    function getUnbondingPeriod() public pure returns (uint256) {
        return UNBONDING_PERIOD;
    }
}
