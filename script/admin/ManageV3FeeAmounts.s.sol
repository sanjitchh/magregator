// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeploymentFactory} from "../../deployments/utils/DeploymentFactory.sol";
import {INetworkDeployments} from "../../deployments/utils/INetworkDeployments.sol";
import {UniswapV3AdapterBase} from "../../src/adapters/UniswapV3AdapterBase.sol";

contract ManageV3FeeAmounts is Script {
    function runStatusUniswapV3() external {
        (INetworkDeployments deployments, UniswapV3AdapterBase adapter) = _adapter(true);
        _logFeeAmounts(deployments.getNetworkName(), "UniswapV3Adapter", address(adapter), adapter.getFeeAmounts());
    }

    function runEnableUniswapV3DefaultFees() external {
        (INetworkDeployments deployments, UniswapV3AdapterBase adapter) = _adapter(true);
        uint24[] memory fees = _defaultUniswapV3Fees();
        _enableFees(deployments.getNetworkName(), "UniswapV3Adapter", address(adapter), fees);
    }

    function runStatusPancakeV3() external {
        (INetworkDeployments deployments, UniswapV3AdapterBase adapter) = _adapter(false);
        _logFeeAmounts(deployments.getNetworkName(), "PancakeV3Adapter", address(adapter), adapter.getFeeAmounts());
    }

    function runEnablePancakeV3DefaultFees() external {
        (INetworkDeployments deployments, UniswapV3AdapterBase adapter) = _adapter(false);
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

    function _adapter(bool isUniswapV3) internal returns (INetworkDeployments deployments, UniswapV3AdapterBase adapter) {
        DeploymentFactory factory = new DeploymentFactory();
        deployments = factory.getDeployments();

        address adapterProxy = isUniswapV3 ? deployments.getUniswapV3Adapter() : deployments.getPancakeV3Adapter();
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
