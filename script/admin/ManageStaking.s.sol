// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeploymentFactory} from "../../deployments/utils/DeploymentFactory.sol";
import {INetworkDeployments} from "../../deployments/utils/INetworkDeployments.sol";
import {MoksaStaking} from "../../src/MoksaStaking.sol";
import {IERC20} from "../../src/interface/IERC20.sol";

contract ManageStaking is Script {
    function runStatus() external {
        (INetworkDeployments deployments, MoksaStaking staking) = _staking();

        console.log("Network:", deployments.getNetworkName());
        console.log("Staking:", address(staking));
        console.log("Staking token:", staking.STAKING_TOKEN());
        console.log("Reward token:", staking.REWARD_TOKEN());
        console.log("Unbonding period:", staking.UNBONDING_PERIOD());
        console.log("Annual emission:", staking.annualEmission());
        console.log("Total active supply:", staking.totalActiveSupply());
        console.log("Total unbonding supply:", staking.totalUnbondingSupply());
        console.log("Last update time:", staking.lastUpdateTime());
        console.log("Reward per token stored:", staking.rewardPerTokenStored());
        console.log("Reward balance owed:", staking.rewardBalanceOwed());
        console.log("Reward treasury balance:", staking.rewardTreasuryBalance());
        console.log("Available reward funding:", staking.availableRewardFunding());
        console.log("Current APY (bps):", staking.currentApyBps());
    }

    function runTokenBalance(address token) external {
        (INetworkDeployments deployments, MoksaStaking staking) = _staking();

        console.log("Network:", deployments.getNetworkName());
        console.log("Staking:", address(staking));
        console.log("Token:", token);
        console.log("Balance:", IERC20(token).balanceOf(address(staking)));
    }

    function runSetUnbondingPeriod(uint256 newUnbondingPeriod) external {
        (INetworkDeployments deployments, MoksaStaking staking) = _staking();

        console.log("Network:", deployments.getNetworkName());
        console.log("Staking:", address(staking));
        console.log("Current unbonding period:", staking.UNBONDING_PERIOD());
        console.log("New unbonding period:", newUnbondingPeriod);

        vm.startBroadcast();
        staking.setUnbondingPeriod(newUnbondingPeriod);
        vm.stopBroadcast();

        console.log("Staking unbonding period updated successfully");
    }

    function runDepositRewards(uint256 amount) external {
        (INetworkDeployments deployments, MoksaStaking staking) = _staking();

        console.log("Network:", deployments.getNetworkName());
        console.log("Staking:", address(staking));
        console.log("Reward token:", staking.REWARD_TOKEN());
        console.log("Deposit amount:", amount);

        vm.startBroadcast();
        staking.depositRewards(amount);
        vm.stopBroadcast();

        console.log("Staking rewards deposited successfully");
    }

    function runSetAnnualEmission(uint256 newAnnualEmission) external {
        (INetworkDeployments deployments, MoksaStaking staking) = _staking();

        console.log("Network:", deployments.getNetworkName());
        console.log("Staking:", address(staking));
        console.log("Current annual emission:", staking.annualEmission());
        console.log("New annual emission:", newAnnualEmission);

        vm.startBroadcast();
        staking.setAnnualEmission(newAnnualEmission);
        vm.stopBroadcast();

        console.log("Staking annual emission updated successfully");
    }

    function runRecoverExcessERC20(address token, uint256 amount, address recipient) external {
        (INetworkDeployments deployments, MoksaStaking staking) = _staking();

        console.log("Network:", deployments.getNetworkName());
        console.log("Staking:", address(staking));
        console.log("Token:", token);
        console.log("Amount:", amount);
        console.log("Recipient:", recipient);

        vm.startBroadcast();
        staking.recoverExcessERC20(token, amount, recipient);
        vm.stopBroadcast();

        console.log("Staking excess token recovered successfully");
    }

    function _staking() internal returns (INetworkDeployments deployments, MoksaStaking staking) {
        DeploymentFactory factory = new DeploymentFactory();
        deployments = factory.getDeployments();

        address stakingProxy = deployments.getStaking();
        require(stakingProxy != address(0), "ManageStaking: staking not configured");
        staking = MoksaStaking(payable(stakingProxy));
    }
}
