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
        console.log("Fee vault:", router.FEE_VAULT());
        console.log("Legacy protocol fee claimer:", router.FEE_CLAIMER());
        console.log("Legacy company fee claimer:", router.COMPANY_FEE_CLAIMER());
        console.log("Operations fee claimer:", router.OPERATIONS_FEE_CLAIMER());
        console.log("Min fee:", router.MIN_FEE());
        console.log("Operations fee bps:", router.OPERATIONS_FEE_BPS());
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
        console.log("Operations reserved (fallback only):", router.OPERATIONS_RESERVED_FEES(token));
        console.log("Legacy company reserved:", router.COMPANY_RESERVED_FEES(token));
        console.log("Legacy protocol reserved:", router.PROTOCOL_RESERVED_FEES(token));
    }

    function runSetFeeVault(address feeVault) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current fee vault:", router.FEE_VAULT());
        console.log("New fee vault:", feeVault);

        vm.startBroadcast();
        router.setFeeVault(feeVault);
        vm.stopBroadcast();

        console.log("Router fee vault updated successfully");
    }

    function runSetFeeClaimer(address feeClaimer) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current legacy protocol fee claimer:", router.FEE_CLAIMER());
        console.log("New legacy protocol fee claimer:", feeClaimer);

        vm.startBroadcast();
        router.setFeeClaimer(feeClaimer);
        vm.stopBroadcast();

        console.log("Router legacy protocol fee claimer updated successfully");
    }

    function runSetCompanyFeeClaimer(address companyFeeClaimer) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current legacy company fee claimer:", router.COMPANY_FEE_CLAIMER());
        console.log("New legacy company fee claimer:", companyFeeClaimer);

        vm.startBroadcast();
        router.setCompanyFeeClaimer(companyFeeClaimer);
        vm.stopBroadcast();

        console.log("Router legacy company fee claimer updated successfully");
    }

    function runSetOperationsFeeClaimer(address operationsFeeClaimer) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current operations fee claimer:", router.OPERATIONS_FEE_CLAIMER());
        console.log("New operations fee claimer:", operationsFeeClaimer);

        vm.startBroadcast();
        router.setOperationsFeeClaimer(operationsFeeClaimer);
        vm.stopBroadcast();

        console.log("Router operations fee claimer updated successfully");
    }

    function runSetOperationsFeeBps(uint256 operationsFeeBps) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current operations fee bps:", router.OPERATIONS_FEE_BPS());
        console.log("New operations fee bps:", operationsFeeBps);

        vm.startBroadcast();
        router.setOperationsFeeBps(operationsFeeBps);
        vm.stopBroadcast();

        console.log("Router operations fee bps updated successfully");
    }

    function runClaimOperationsFees(address token, uint256 amount) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Token:", token);
        console.log("Reserved operations balance (fallback only):", router.OPERATIONS_RESERVED_FEES(token));
        console.log("Amount:", amount);

        vm.startBroadcast();
        router.claimOperationsFees(token, amount);
        vm.stopBroadcast();

        console.log("Router operations fees claimed successfully");
    }

    function runClaimCompanyFees(address token, uint256 amount) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Token:", token);
        console.log("Legacy company reserved:", router.COMPANY_RESERVED_FEES(token));
        console.log("Amount:", amount);

        vm.startBroadcast();
        router.claimCompanyFees(token, amount);
        vm.stopBroadcast();

        console.log("Router legacy company fees claimed successfully");
    }

    function runClaimProtocolFees(address token, uint256 amount) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Token:", token);
        console.log("Legacy protocol reserved:", router.PROTOCOL_RESERVED_FEES(token));
        console.log("Amount:", amount);

        vm.startBroadcast();
        router.claimProtocolFees(token, amount);
        vm.stopBroadcast();

        console.log("Router legacy protocol fees claimed successfully");
    }

    function _router() internal returns (INetworkDeployments deployments, MoksaRouter router) {
        DeploymentFactory factory = new DeploymentFactory();
        deployments = factory.getDeployments();

        address routerProxy = deployments.getRouter();
        require(routerProxy != address(0), "ManageRouterFees: router not configured");
        router = MoksaRouter(payable(routerProxy));
    }
}
