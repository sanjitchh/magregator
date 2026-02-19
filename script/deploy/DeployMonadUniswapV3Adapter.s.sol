// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/adapters/UniswapV3Adapter.sol";

contract DeployMonadUniswapV3Adapter is Script {
    function run() external {
        vm.startBroadcast();

        address factory = vm.envAddress("MONAD_UNIV3_FACTORY");
        address quoter = vm.envAddress("MONAD_UNIV3_QUOTER");
        uint256 quoterGasLimit = vm.envOr("MONAD_UNIV3_QUOTER_GAS_LIMIT", uint256(500_000));
        uint256 gasEstimate = vm.envOr("MONAD_UNIV3_GAS_ESTIMATE", uint256(185_000));

        require(factory != address(0), "MONAD_UNIV3_FACTORY not set");
        require(quoter != address(0), "MONAD_UNIV3_QUOTER not set");

        uint24[] memory defaultFees = new uint24[](4);
        defaultFees[0] = 100;
        defaultFees[1] = 500;
        defaultFees[2] = 3000;
        defaultFees[3] = 10_000;

        UniswapV3Adapter adapter =
            new UniswapV3Adapter("MonadUniswapV3Adapter", gasEstimate, quoterGasLimit, quoter, factory, defaultFees);

        console.log("Monad UniswapV3Adapter deployed at:", address(adapter));
        console.log("Factory:", factory);
        console.log("Quoter:", quoter);
        console.log("Gas estimate:", adapter.swapGasEstimate());

        vm.stopBroadcast();
    }
}
