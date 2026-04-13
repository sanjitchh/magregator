// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeploymentFactory} from "../../deployments/utils/DeploymentFactory.sol";
import {INetworkDeployments} from "../../deployments/utils/INetworkDeployments.sol";
import {MoksaStaking} from "../../src/MoksaStaking.sol";

contract UpgradeStaking is Script {
    function run() external {
        DeploymentFactory factory = new DeploymentFactory();
        INetworkDeployments deployments = factory.getDeployments();

        address stakingProxy = deployments.getStaking();
        uint256 upgradeGasLimit = vm.envOr("STAKING_UPGRADE_GAS_LIMIT", uint256(200_000));
        require(stakingProxy != address(0), "UpgradeStaking: staking not configured");

        console.log("Network:", deployments.getNetworkName());
        console.log("Staking proxy:", stakingProxy);
        console.log("Upgrade gas limit:", upgradeGasLimit);

        vm.startBroadcast();

        address newImplementation = address(new MoksaStaking());
        MoksaStaking(payable(stakingProxy)).upgradeTo{gas: upgradeGasLimit}(newImplementation);

        vm.stopBroadcast();

        console.log("New staking implementation:", newImplementation);
        console.log("Staking upgraded successfully");
    }
}
