// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/adapters/UniswapV2Adapter.sol";

contract DeployMonadUniswapV2Adapter is Script {
    function run() external {
        vm.startBroadcast();

        address factory = vm.envAddress("MONAD_UNIV2_FACTORY");
        uint256 fee = vm.envOr("MONAD_UNIV2_FEE_BPS", uint256(3));
        uint256 gasEstimate = vm.envOr("MONAD_UNIV2_GAS_ESTIMATE", uint256(150_000));

        require(factory != address(0), "MONAD_UNIV2_FACTORY not set");

        UniswapV2Adapter adapter = new UniswapV2Adapter("MonadUniswapV2Adapter", factory, fee, gasEstimate);

        console.log("Monad UniswapV2Adapter deployed at:", address(adapter));
        console.log("Factory:", factory);
        console.log("Fee bps:", fee);
        console.log("Gas estimate:", adapter.swapGasEstimate());

        vm.stopBroadcast();
    }
}
