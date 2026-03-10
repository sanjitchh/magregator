// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeploymentFactory} from "../../deployments/utils/DeploymentFactory.sol";
import {INetworkDeployments} from "../../deployments/utils/INetworkDeployments.sol";
import {MoksaRouter} from "../../src/MoksaRouter.sol";

contract UpgradeRouter is Script {
    function run() external {
        DeploymentFactory factory = new DeploymentFactory();
        INetworkDeployments deployments = factory.getDeployments();

        address routerProxy = deployments.getRouter();
        require(routerProxy != address(0), "UpgradeRouter: router not configured");

        console.log("Network:", deployments.getNetworkName());
        console.log("Router proxy:", routerProxy);

        vm.startBroadcast();

        address newImplementation = address(new MoksaRouter());
        MoksaRouter(payable(routerProxy)).upgradeTo(newImplementation);

        vm.stopBroadcast();

        console.log("New router implementation:", newImplementation);
        console.log("Router upgraded successfully");
    }
}
