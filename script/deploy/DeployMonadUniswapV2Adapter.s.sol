// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../src/adapters/UniswapV2Adapter.sol";

contract DeployMonadUniswapV2Adapter is Script {
    function run() external {
        vm.startBroadcast();

        address factory = vm.envAddress("MONAD_UNIV2_FACTORY");
        uint256 fee = vm.envOr("MONAD_UNIV2_FEE_BPS", uint256(3));
        uint256 gasEstimate = vm.envOr("MONAD_UNIV2_GAS_ESTIMATE", uint256(150_000));

        require(factory != address(0), "MONAD_UNIV2_FACTORY not set");

        address maintainer = vm.envAddress("MONAD_INITIAL_MAINTAINER");
        UniswapV2Adapter implementation = new UniswapV2Adapter();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(
                UniswapV2Adapter.initialize,
                ("MonadUniswapV2Adapter", factory, fee, gasEstimate, maintainer)
            )
        );
        UniswapV2Adapter adapter = UniswapV2Adapter(payable(address(proxy)));

        console.log("Monad UniswapV2Adapter implementation:", address(implementation));
        console.log("Monad UniswapV2Adapter proxy:", address(adapter));
        console.log("Factory:", factory);
        console.log("Fee bps:", fee);
        console.log("Gas estimate:", adapter.swapGasEstimate());

        vm.stopBroadcast();
    }
}
