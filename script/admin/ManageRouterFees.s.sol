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
        console.log("Protocol fee claimer:", router.FEE_CLAIMER());
        console.log("Company fee claimer:", router.COMPANY_FEE_CLAIMER());
        console.log("Operations fee claimer:", router.OPERATIONS_FEE_CLAIMER());
        console.log("Min fee:", router.MIN_FEE());
        console.log("Operations fee bps:", router.OPERATIONS_FEE_BPS());
        console.log("Company pre-cap enabled:", router.COMPANY_PRE_CAP_ENABLED());
        console.log("Company post-cap fee bps:", router.COMPANY_POST_CAP_FEE_BPS());
        console.log("Company fee cap USD (8 decimals):", router.COMPANY_FEE_CAP_USD());
        console.log("Company accrued USD (8 decimals):", router.companyAccruedUsd());
        console.log("Remaining company cap USD (8 decimals):", router.remainingCompanyFeeCapUsd());
        console.log("Price feed staleness:", router.PRICE_FEED_STALENESS());
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
        console.log("Company reserved:", router.COMPANY_RESERVED_FEES(token));
        console.log("Protocol reserved:", router.PROTOCOL_RESERVED_FEES(token));
        console.log("Legacy special reserved:", router.SPECIAL_RESERVED_FEES(token));
    }

    function runSetFeeClaimer(address feeClaimer) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current protocol fee claimer:", router.FEE_CLAIMER());
        console.log("New protocol fee claimer:", feeClaimer);

        vm.startBroadcast();
        router.setFeeClaimer(feeClaimer);
        vm.stopBroadcast();

        console.log("Router protocol fee claimer updated successfully");
    }

    function runSetCompanyFeeClaimer(address companyFeeClaimer) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current company fee claimer:", router.COMPANY_FEE_CLAIMER());
        console.log("New company fee claimer:", companyFeeClaimer);

        vm.startBroadcast();
        router.setCompanyFeeClaimer(companyFeeClaimer);
        vm.stopBroadcast();

        console.log("Router company fee claimer updated successfully");
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

    function runSetCompanyPreCapEnabled(bool companyPreCapEnabled) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current company pre-cap enabled:", router.COMPANY_PRE_CAP_ENABLED());
        console.log("New company pre-cap enabled:", companyPreCapEnabled);

        vm.startBroadcast();
        router.setCompanyPreCapEnabled(companyPreCapEnabled);
        vm.stopBroadcast();

        console.log("Router company pre-cap flag updated successfully");
    }

    function runSetCompanyPostCapFeeBps(uint256 companyPostCapFeeBps) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current company post-cap fee bps:", router.COMPANY_POST_CAP_FEE_BPS());
        console.log("New company post-cap fee bps:", companyPostCapFeeBps);

        vm.startBroadcast();
        router.setCompanyPostCapFeeBps(companyPostCapFeeBps);
        vm.stopBroadcast();

        console.log("Router company post-cap fee bps updated successfully");
    }

    function runSetCompanyFeeCapUsdWhole(uint256 wholeUsd) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();
        uint256 capUsd = wholeUsd * 1e8;

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current company fee cap USD (8 decimals):", router.COMPANY_FEE_CAP_USD());
        console.log("New company fee cap USD (8 decimals):", capUsd);

        vm.startBroadcast();
        router.setCompanyFeeCapUsd(capUsd);
        vm.stopBroadcast();

        console.log("Router company fee cap updated successfully");
    }

    function runSetFeePriceFeed(address token, address priceFeed) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Token:", token);
        console.log("Current price feed:", router.FEE_PRICE_FEEDS(token));
        console.log("New price feed:", priceFeed);

        vm.startBroadcast();
        router.setFeePriceFeed(token, priceFeed);
        vm.stopBroadcast();

        console.log("Router fee price feed updated successfully");
    }

    function runSetPriceFeedStaleness(uint256 priceFeedStaleness) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current price feed staleness:", router.PRICE_FEED_STALENESS());
        console.log("New price feed staleness:", priceFeedStaleness);

        vm.startBroadcast();
        router.setPriceFeedStaleness(priceFeedStaleness);
        vm.stopBroadcast();

        console.log("Router price feed staleness updated successfully");
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
        console.log("Reserved company balance (pre-cap or fallback only):", router.COMPANY_RESERVED_FEES(token));
        console.log("Amount:", amount);

        vm.startBroadcast();
        router.claimCompanyFees(token, amount);
        vm.stopBroadcast();

        console.log("Router company fees claimed successfully");
    }

    function runClaimProtocolFees(address token, uint256 amount) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Token:", token);
        console.log("Reserved protocol balance (fallback only):", router.PROTOCOL_RESERVED_FEES(token));
        console.log("Amount:", amount);

        vm.startBroadcast();
        router.claimProtocolFees(token, amount);
        vm.stopBroadcast();

        console.log("Router protocol fees claimed successfully");
    }

    function runFeeUsdValue(address token, uint256 amount) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Token:", token);
        console.log("Amount:", amount);
        console.log("USD value (8 decimals):", router.getFeeUsdValue(token, amount));
    }

    function _router() internal returns (INetworkDeployments deployments, MoksaRouter router) {
        DeploymentFactory factory = new DeploymentFactory();
        deployments = factory.getDeployments();

        address routerProxy = deployments.getRouter();
        require(routerProxy != address(0), "ManageRouterFees: router not configured");
        router = MoksaRouter(payable(routerProxy));
    }
}
