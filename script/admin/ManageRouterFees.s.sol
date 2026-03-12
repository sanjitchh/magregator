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
        console.log("Special redeem enabled:", router.SPECIAL_REDEEM_ENABLED());
        console.log("Deployer redeemer:", router.DEPLOYER_REDEEMER());
        console.log("Special redeem cap USD (8 decimals):", router.SPECIAL_REDEEM_CAP_USD());
        console.log("Special accrued USD (8 decimals):", router.specialAccruedUsd());
        console.log("Special redeemed USD (8 decimals):", router.specialRedeemedUsd());
        console.log("Remaining special redeem USD (8 decimals):", router.remainingSpecialRedeemUsd());
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
        console.log("Reserved special token balance:", router.SPECIAL_RESERVED_FEES(token));
        console.log("Reserved special USD (8 decimals):", router.SPECIAL_RESERVED_USD(token));
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

    function runSetDeployerRedeemer(address deployerRedeemer) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current deployer redeemer:", router.DEPLOYER_REDEEMER());
        console.log("New deployer redeemer:", deployerRedeemer);

        vm.startBroadcast();
        router.setDeployerRedeemer(deployerRedeemer);
        vm.stopBroadcast();

        console.log("Router deployer redeemer updated successfully");
    }

    function runSetSpecialRedeemEnabled(bool specialRedeemEnabled) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current special redeem enabled:", router.SPECIAL_REDEEM_ENABLED());
        console.log("New special redeem enabled:", specialRedeemEnabled);

        vm.startBroadcast();
        router.setSpecialRedeemEnabled(specialRedeemEnabled);
        vm.stopBroadcast();

        console.log("Router special redeem mode updated successfully");
    }

    function runSetSpecialRedeemCapUsdWhole(uint256 wholeUsd) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();
        uint256 capUsd = wholeUsd * 1e8;

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Current special redeem cap USD (8 decimals):", router.SPECIAL_REDEEM_CAP_USD());
        console.log("New special redeem cap USD (8 decimals):", capUsd);

        vm.startBroadcast();
        router.setSpecialRedeemCapUsd(capUsd);
        vm.stopBroadcast();

        console.log("Router special redeem cap updated successfully");
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

    function runClaimSpecialFees(address token, uint256 amount) external {
        (INetworkDeployments deployments, MoksaRouter router) = _router();

        console.log("Network:", deployments.getNetworkName());
        console.log("Router:", address(router));
        console.log("Token:", token);
        console.log("Reserved token balance:", router.SPECIAL_RESERVED_FEES(token));
        console.log("Amount:", amount);

        vm.startBroadcast();
        router.claimSpecialFees(token, amount);
        vm.stopBroadcast();

        console.log("Router special fees claimed successfully");
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
