// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/adapters/UniswapV4Adapter.sol";

contract DeployMonadUniswapV4Adapter is Script {
    function run() external {
        vm.startBroadcast();

        address poolManager = vm.envAddress("MONAD_UNIV4_POOL_MANAGER");
        address staticQuoter = vm.envAddress("MONAD_UNIV4_STATIC_QUOTER");
        address wrappedNative = vm.envAddress("MONAD_WRAPPED_NATIVE");
        uint256 gasEstimate = vm.envOr("MONAD_UNIV4_GAS_ESTIMATE", uint256(200_000));

        require(poolManager != address(0), "MONAD_UNIV4_POOL_MANAGER not set");
        require(staticQuoter != address(0), "MONAD_UNIV4_STATIC_QUOTER not set");
        require(wrappedNative != address(0), "MONAD_WRAPPED_NATIVE not set");

        UniswapV4Adapter adapter =
            new UniswapV4Adapter("MonadUniswapV4Adapter", gasEstimate, staticQuoter, poolManager, wrappedNative);

        console.log("Monad UniswapV4Adapter deployed at:", address(adapter));
        console.log("Pool Manager:", poolManager);
        console.log("Static Quoter:", staticQuoter);
        console.log("Wrapped Native:", wrappedNative);
        console.log("Gas estimate:", adapter.swapGasEstimate());
        console.log("Pools must be added with ManageUniswapV4Pools after deployment.");

        vm.stopBroadcast();
    }
}
