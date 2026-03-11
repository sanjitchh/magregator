// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeploymentFactory} from "../../deployments/utils/DeploymentFactory.sol";
import {INetworkDeployments} from "../../deployments/utils/INetworkDeployments.sol";
import {MoksaRouter} from "../../src/MoksaRouter.sol";
import {IERC20} from "../../src/interface/IERC20.sol";

contract ManageRouterFees is Script {
    function runStatus() external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Fee claimer:", router.FEE_CLAIMER());
        console.log("Hold fees:", router.HOLD_FEES());
        console.log("Min fee:", router.MIN_FEE());
    }

    function runNativeBalance() external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Native balance:", address(router).balance);
    }

    function runTokenBalance(address token) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Token:", token);
        console.log("Token balance:", IERC20(token).balanceOf(address(router)));
    }

    function runSetHoldFees(bool holdFees) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current hold fees:", router.HOLD_FEES());
        console.log("New hold fees:", holdFees);

        vm.startBroadcast();
        router.setHoldFees(holdFees);
        vm.stopBroadcast();

        console.log("Router hold fees updated successfully");
    }

    function runSetFeeClaimer(address feeClaimer) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current fee claimer:", router.FEE_CLAIMER());
        console.log("New fee claimer:", feeClaimer);

        vm.startBroadcast();
        router.setFeeClaimer(feeClaimer);
        vm.stopBroadcast();

        console.log("Router fee claimer updated successfully");
    }

    function runClaimFees(address token, address to, uint256 amount) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Token:", token);
        console.log("Recipient:", to);
        console.log("Amount:", amount);

        vm.startBroadcast();
        router.claimFees(token, to, amount);
        vm.stopBroadcast();

        console.log("Router fees claimed successfully");
    }

    function _router() internal returns (INetworkDeployments deployments, MoksaRouter router) {
        DeploymentFactory factory = new DeploymentFactory();
        deployments = factory.getDeployments();

        address routerProxy = deployments.getRouter();
        require(routerProxy != address(0), "ManageRouterFees: router not configured");
        router = MoksaRouter(payable(routerProxy));
    }
}
