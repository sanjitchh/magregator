// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/adapters/KuruAdapter.sol";

contract DeployMonadKuruAdapter is Script {
    function run() external {
        vm.startBroadcast();

        address wmon = vm.envAddress("MONAD_WRAPPED_NATIVE");
        address ausd = vm.envAddress("MONAD_AUSD");
        address usdc = vm.envAddress("MONAD_USDC");
        address monAusdMarket = vm.envAddress("MONAD_KURU_MON_AUSD_MARKET");
        address monUsdcMarket = vm.envAddress("MONAD_KURU_MON_USDC_MARKET");
        uint256 gasEstimate = vm.envOr("MONAD_KURU_GAS_ESTIMATE", uint256(300_000));

        require(wmon != address(0), "MONAD_WRAPPED_NATIVE not set");
        require(ausd != address(0), "MONAD_AUSD not set");
        require(usdc != address(0), "MONAD_USDC not set");
        require(monAusdMarket != address(0), "MONAD_KURU_MON_AUSD_MARKET not set");
        require(monUsdcMarket != address(0), "MONAD_KURU_MON_USDC_MARKET not set");

        KuruAdapter adapter =
            new KuruAdapter("MonadKuruAdapter", gasEstimate, wmon, ausd, usdc, monAusdMarket, monUsdcMarket);

        console.log("Monad KuruAdapter deployed at:", address(adapter));
        console.log("WMON:", wmon);
        console.log("AUSD:", ausd);
        console.log("USDC:", usdc);
        console.log("MON-AUSD market:", monAusdMarket);
        console.log("MON-USDC market:", monUsdcMarket);
        console.log("Gas estimate:", adapter.swapGasEstimate());

        vm.stopBroadcast();
    }
}
