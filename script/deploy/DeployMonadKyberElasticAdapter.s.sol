// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../src/adapters/KyberElasticAdapter.sol";

contract DeployMonadKyberElasticAdapter is Script {
    function run() external {
        vm.startBroadcast();

        address quoter = vm.envAddress("MONAD_KYBER_QUOTER");
        uint256 quoterGasLimit = vm.envOr("MONAD_KYBER_QUOTER_GAS_LIMIT", uint256(1_500_000));
        uint256 gasEstimate = vm.envOr("MONAD_KYBER_GAS_ESTIMATE", uint256(220_000));
        uint256 poolCount = vm.envOr("MONAD_KYBER_POOL_COUNT", uint256(0));

        require(quoter != address(0), "MONAD_KYBER_QUOTER not set");
        require(poolCount > 0, "MONAD_KYBER_POOL_COUNT must be > 0");

        address[] memory whitelistedPools = new address[](poolCount);
        for (uint256 i = 0; i < poolCount; i++) {
            string memory key = string.concat("MONAD_KYBER_POOL_", vm.toString(i));
            address pool = vm.envAddress(key);
            require(pool != address(0), "Kyber pool env var not set");
            whitelistedPools[i] = pool;
        }

        address maintainer = vm.envAddress("MONAD_INITIAL_MAINTAINER");
        KyberElasticAdapter implementation = new KyberElasticAdapter();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(
                KyberElasticAdapter.initialize,
                ("MonadKyberElasticAdapter", gasEstimate, quoterGasLimit, quoter, whitelistedPools, maintainer)
            )
        );
        KyberElasticAdapter adapter = KyberElasticAdapter(payable(address(proxy)));

        console.log("Monad KyberElasticAdapter implementation:", address(implementation));
        console.log("Monad KyberElasticAdapter proxy:", address(adapter));
        console.log("Quoter:", quoter);
        console.log("Quote gas limit:", quoterGasLimit);
        console.log("Swap gas estimate:", adapter.swapGasEstimate());
        console.log("Whitelisted pools:", poolCount);
        for (uint256 i = 0; i < poolCount; i++) {
            console.log("  -", whitelistedPools[i]);
        }

        vm.stopBroadcast();
    }
}
