// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/adapters/WNativeAdapter.sol";

contract DeployMonadWNativeAdapter is Script {
    function run() external {
        vm.startBroadcast();

        address wrappedNative = vm.envAddress("MONAD_WRAPPED_NATIVE");
        uint256 gasEstimate = vm.envOr("MONAD_WNATIVE_GAS_ESTIMATE", uint256(80_000));

        require(wrappedNative != address(0), "MONAD_WRAPPED_NATIVE not set");

        WNativeAdapter adapter = new WNativeAdapter(wrappedNative, gasEstimate);

        console.log("Monad WNativeAdapter deployed at:", address(adapter));
        console.log("Wrapped Native:", wrappedNative);
        console.log("Gas estimate:", adapter.swapGasEstimate());

        vm.stopBroadcast();
    }
}
