// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeploymentFactory} from "../../deployments/utils/DeploymentFactory.sol";
import {INetworkDeployments} from "../../deployments/utils/INetworkDeployments.sol";
import {UniswapV3AdapterBase} from "../../src/adapters/UniswapV3AdapterBase.sol";

contract ManageV3FeeAmounts is Script {
    function runStatusUniswapV3() external {
        (INetworkDeployments deployments, UniswapV3AdapterBase adapter) = _adapter(1);
        _logFeeAmounts(deployments.getNetworkName(), "UniswapV3Adapter", address(adapter), adapter.getFeeAmounts());
    }

    function runEnableUniswapV3DefaultFees() external {
        (INetworkDeployments deployments, UniswapV3AdapterBase adapter) = _adapter(1);
        uint24[] memory fees = _defaultUniswapV3Fees();
        _enableFees(deployments.getNetworkName(), "UniswapV3Adapter", address(adapter), fees);
    }

    function runStatusSushiV3() external {
        (INetworkDeployments deployments, UniswapV3AdapterBase adapter) = _adapter(2);
        _logFeeAmounts(deployments.getNetworkName(), "SushiV3Adapter", address(adapter), adapter.getFeeAmounts());
    }

    function runEnableSushiV3DefaultFees() external {
        (INetworkDeployments deployments, UniswapV3AdapterBase adapter) = _adapter(2);
        uint24[] memory fees = _defaultUniswapV3Fees();
        _enableFees(deployments.getNetworkName(), "SushiV3Adapter", address(adapter), fees);
    }

    function runStatusPancakeV3() external {
        (INetworkDeployments deployments, UniswapV3AdapterBase adapter) = _adapter(3);
        _logFeeAmounts(deployments.getNetworkName(), "PancakeV3Adapter", address(adapter), adapter.getFeeAmounts());
    }

    function runEnablePancakeV3DefaultFees() external {
        (INetworkDeployments deployments, UniswapV3AdapterBase adapter) = _adapter(3);
        uint24[] memory fees = _defaultPancakeV3Fees();
        _enableFees(deployments.getNetworkName(), "PancakeV3Adapter", address(adapter), fees);
    }

    function _enableFees(
        string memory networkName,
        string memory adapterName,
        address adapterAddress,
        uint24[] memory fees
    ) internal {
        console.log("Network:", networkName);
        console.log("Adapter:", adapterName);
        console.log("Adapter proxy:", adapterAddress);
        console.log("Enabling %d fee tiers", fees.length);
        _printFees(fees);

        vm.startBroadcast();
        UniswapV3AdapterBase(payable(adapterAddress)).enableFeeAmounts(fees);
        vm.stopBroadcast();

        console.log("Adapter fee tiers enabled successfully");
    }

    function _logFeeAmounts(
        string memory networkName,
        string memory adapterName,
        address adapterAddress,
        uint24[] memory fees
    ) internal view {
        console.log("Network:", networkName);
        console.log("Adapter:", adapterName);
        console.log("Adapter proxy:", adapterAddress);
        console.log("Enabled %d fee tiers", fees.length);
        _printFees(fees);
    }

    function _printFees(uint24[] memory fees) internal pure {
        for (uint256 i = 0; i < fees.length; i++) {
            console.log("  [%d] %s", i, uint256(fees[i]));
        }
    }

    function _adapter(uint8 adapterType) internal returns (INetworkDeployments deployments, UniswapV3AdapterBase adapter) {
        DeploymentFactory factory = new DeploymentFactory();
        deployments = factory.getDeployments();

        address adapterProxy;
        if (adapterType == 1) {
            adapterProxy = deployments.getUniswapV3Adapter();
        } else if (adapterType == 2) {
            adapterProxy = deployments.getSushiV3Adapter();
        } else if (adapterType == 3) {
            adapterProxy = deployments.getPancakeV3Adapter();
        } else {
            revert("ManageV3FeeAmounts: unsupported adapter type");
        }
        require(adapterProxy != address(0), "ManageV3FeeAmounts: adapter not configured");
        adapter = UniswapV3AdapterBase(payable(adapterProxy));
    }

    function _defaultUniswapV3Fees() internal pure returns (uint24[] memory fees) {
        fees = new uint24[](4);
        fees[0] = 100;
        fees[1] = 500;
        fees[2] = 3000;
        fees[3] = 10_000;
    }

    function _defaultPancakeV3Fees() internal pure returns (uint24[] memory fees) {
        fees = new uint24[](3);
        fees[0] = 100;
        fees[1] = 500;
        fees[2] = 10_000;
    }
}
