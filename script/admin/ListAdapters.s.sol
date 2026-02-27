// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeploymentFactory} from "../../deployments/utils/DeploymentFactory.sol";
import {INetworkDeployments} from "../../deployments/utils/INetworkDeployments.sol";
import {MoksaRouter} from "../../src/MoksaRouter.sol";
import {IAdapter} from "../../src/interface/IAdapter.sol";

/**
 * @title ListAdapters
 * @notice Admin script to list all adapters currently registered in the MoksaRouter
 *
 * @dev This script queries the MoksaRouter contract to display all currently registered
 *      adapters with their addresses and names. It provides a quick overview of the
 *      router's current configuration.
 *
 * USAGE:
 * ======
 *
 * List adapters on any supported network:
 * forge script script/admin/ListAdapters.s.sol --rpc-url <network>
 *
 * Example:
 * - forge script script/admin/ListAdapters.s.sol --rpc-url monad
 *
 */
contract ListAdapters is Script {
    function run() external {
        DeploymentFactory factory = new DeploymentFactory();

        // Get deployments for current network
        INetworkDeployments deployments = factory.getDeployments();

        console.log("Network:", deployments.getNetworkName());
        console.log("Chain ID:", deployments.getChainId());
        console.log("MoksaRouter:", deployments.getRouter());
        console.log("");

        // Verify router is deployed
        if (deployments.getRouter() == address(0)) {
            console.log("Error: Router address is not set for this network");
            return;
        }

        MoksaRouter moksaRouter = MoksaRouter(payable(deployments.getRouter()));
        uint256 adapterCount = moksaRouter.adaptersCount();
        console.log("Total adapters:", adapterCount);
        console.log("");

        if (adapterCount == 0) {
            console.log("No adapters found in router");
            return;
        }

        // List all adapters
        for (uint256 i = 0; i < adapterCount; i++) {
            address adapterAddr = moksaRouter.ADAPTERS(i);

            // Try to get adapter name, but handle failures gracefully
            string memory adapterName = IAdapter(adapterAddr).name();
            console.log("[%d] %s - %s", i, adapterAddr, adapterName);
        }
    }
}
