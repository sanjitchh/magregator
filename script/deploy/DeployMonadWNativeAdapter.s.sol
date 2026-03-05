// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../src/adapters/WNativeAdapter.sol";

contract DeployMonadWNativeAdapter is Script {
    function run() external {
        vm.startBroadcast();

        address wrappedNative = vm.envAddress("MONAD_WRAPPED_NATIVE");
        uint256 gasEstimate = vm.envOr("MONAD_WNATIVE_GAS_ESTIMATE", uint256(80_000));

        require(wrappedNative != address(0), "MONAD_WRAPPED_NATIVE not set");

        address maintainer = vm.envAddress("MONAD_INITIAL_MAINTAINER");
        WNativeAdapter implementation = new WNativeAdapter();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(WNativeAdapter.initialize, (wrappedNative, gasEstimate, maintainer))
        );
        WNativeAdapter adapter = WNativeAdapter(payable(address(proxy)));

        console.log("Monad WNativeAdapter implementation:", address(implementation));
        console.log("Monad WNativeAdapter proxy:", address(adapter));
        console.log("Wrapped Native:", wrappedNative);
        console.log("Gas estimate:", adapter.swapGasEstimate());

        vm.stopBroadcast();
    }
}
