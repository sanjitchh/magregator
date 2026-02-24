// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/adapters/PancakeV3Adapter.sol";

contract DeployMonadPancakeV3Adapter is Script {
    function run() external {
        vm.startBroadcast();

        address factory = vm.envAddress("MONAD_PANCAKEV3_FACTORY");
        address quoter = vm.envAddress("MONAD_PANCAKEV3_QUOTER");
        uint256 quoterGasLimit = vm.envOr("MONAD_PANCAKEV3_QUOTER_GAS_LIMIT", uint256(1_500_000));
        uint256 gasEstimate = vm.envOr("MONAD_PANCAKEV3_GAS_ESTIMATE", uint256(185_000));

        require(factory != address(0), "MONAD_PANCAKEV3_FACTORY not set");
        require(quoter != address(0), "MONAD_PANCAKEV3_QUOTER not set");

        uint24[] memory defaultFees = new uint24[](3);
        defaultFees[0] = 100;
        defaultFees[1] = 500;
        defaultFees[2] = 10_000;

        PancakeV3Adapter adapter =
            new PancakeV3Adapter("MonadPancakeV3Adapter", gasEstimate, quoterGasLimit, quoter, factory, defaultFees);

        console.log("Monad PancakeV3Adapter deployed at:", address(adapter));
        console.log("Factory:", factory);
        console.log("Quoter:", quoter);
        console.log("Quote gas limit:", quoterGasLimit);
        console.log("Gas estimate:", adapter.swapGasEstimate());

        vm.stopBroadcast();
    }
}
