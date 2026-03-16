// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeploymentFactory} from "../../deployments/utils/DeploymentFactory.sol";
import {INetworkDeployments} from "../../deployments/utils/INetworkDeployments.sol";
import {IMoksaRouter, Query} from "../../src/interface/IMoksaRouter.sol";
import {IAdapter} from "../../src/interface/IAdapter.sol";

contract CheckAdapterQuotes is Script {
    function runPair(address tokenIn, address tokenOut, uint256 amountIn) external {
        DeploymentFactory factory = new DeploymentFactory();
        INetworkDeployments deployments = factory.getDeployments();
        IMoksaRouter router = IMoksaRouter(deployments.getRouter());

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", deployments.getRouter());
        console.log("Token in:", tokenIn);
        console.log("Token out:", tokenOut);
        console.log("Amount in:", amountIn);
        console.log("=================================");

        uint256 adapterCount = router.adaptersCount();
        if (adapterCount == 0) {
            console.log("Router has no adapters configured.");
            return;
        }

        for (uint256 i = 0; i < adapterCount; i++) {
            address adapter = IAdapterProvider(address(router)).ADAPTERS(i);
            string memory adapterName = IAdapter(adapter).name();
            uint256 amountOut = IAdapter(adapter).query(amountIn, tokenIn, tokenOut);
            console.log("Adapter index:", i);
            console.log("Adapter:", adapter);
            console.log("Name:", adapterName);
            console.log("Amount out:", amountOut);
            console.log("");
        }

        Query memory bestDirect = router.queryNoSplit(amountIn, tokenIn, tokenOut);
        console.log("Best direct adapter:", bestDirect.adapter);
        console.log("Best direct amountOut:", bestDirect.amountOut);
    }
}

interface IAdapterProvider {
    function ADAPTERS(uint256 index) external view returns (address);
}
