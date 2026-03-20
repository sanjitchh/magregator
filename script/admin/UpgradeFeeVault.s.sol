// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeploymentFactory} from "../../deployments/utils/DeploymentFactory.sol";
import {INetworkDeployments} from "../../deployments/utils/INetworkDeployments.sol";
import {FeeVault} from "../../src/FeeVault.sol";

contract UpgradeFeeVault is Script {
    function run() external {
        DeploymentFactory factory = new DeploymentFactory();
        INetworkDeployments deployments = factory.getDeployments();

        address feeVaultProxy = deployments.getFeeVault();
        uint256 upgradeGasLimit = vm.envOr("FEE_VAULT_UPGRADE_GAS_LIMIT", uint256(200_000));
        require(feeVaultProxy != address(0), "UpgradeFeeVault: fee vault not configured");

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault proxy:", feeVaultProxy);
        console.log("Upgrade gas limit:", upgradeGasLimit);

        vm.startBroadcast();

        address newImplementation = address(new FeeVault());
        FeeVault(payable(feeVaultProxy)).upgradeTo{gas: upgradeGasLimit}(newImplementation);

        vm.stopBroadcast();

        console.log("New fee vault implementation:", newImplementation);
        console.log("FeeVault upgraded successfully");
    }
}
