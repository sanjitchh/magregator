// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeploymentFactory} from "../../deployments/utils/DeploymentFactory.sol";
import {INetworkDeployments} from "../../deployments/utils/INetworkDeployments.sol";
import {UniswapV2Adapter} from "../../src/adapters/UniswapV2Adapter.sol";
import {UniswapV3Adapter} from "../../src/adapters/UniswapV3Adapter.sol";
import {SushiV3Adapter} from "../../src/adapters/SushiV3Adapter.sol";
import {PancakeV3Adapter} from "../../src/adapters/PancakeV3Adapter.sol";
import {KyberElasticAdapter} from "../../src/adapters/KyberElasticAdapter.sol";
import {UniswapV4Adapter} from "../../src/adapters/UniswapV4Adapter.sol";
import {WNativeAdapter} from "../../src/adapters/WNativeAdapter.sol";
import {KuruAdapter} from "../../src/adapters/KuruAdapter.sol";

contract UpgradeAdapters is Script {
    uint8 internal constant ADAPTER_UNISWAP_V2 = 1;
    uint8 internal constant ADAPTER_UNISWAP_V3 = 2;
    uint8 internal constant ADAPTER_SUSHI_V3 = 3;
    uint8 internal constant ADAPTER_PANCAKE_V3 = 4;
    uint8 internal constant ADAPTER_KYBER = 5;
    uint8 internal constant ADAPTER_UNISWAP_V4 = 6;
    uint8 internal constant ADAPTER_WNATIVE = 7;
    uint8 internal constant ADAPTER_KURU = 8;

    function runUniswapV2() external {
        _upgradeAdapter(_deployments().getUniswapV2Adapter(), "UniswapV2Adapter", ADAPTER_UNISWAP_V2);
    }

    function runUniswapV2(address adapterProxy) external {
        _upgradeAdapter(adapterProxy, "UniswapV2Adapter", ADAPTER_UNISWAP_V2);
    }

    function runUniswapV3() external {
        _upgradeAdapter(_deployments().getUniswapV3Adapter(), "UniswapV3Adapter", ADAPTER_UNISWAP_V3);
    }

    function runUniswapV3(address adapterProxy) external {
        _upgradeAdapter(adapterProxy, "UniswapV3Adapter", ADAPTER_UNISWAP_V3);
    }

    function runSushiV3() external {
        _upgradeAdapter(_deployments().getSushiV3Adapter(), "SushiV3Adapter", ADAPTER_SUSHI_V3);
    }

    function runSushiV3(address adapterProxy) external {
        _upgradeAdapter(adapterProxy, "SushiV3Adapter", ADAPTER_SUSHI_V3);
    }

    function runPancakeV3() external {
        _upgradeAdapter(_deployments().getPancakeV3Adapter(), "PancakeV3Adapter", ADAPTER_PANCAKE_V3);
    }

    function runPancakeV3(address adapterProxy) external {
        _upgradeAdapter(adapterProxy, "PancakeV3Adapter", ADAPTER_PANCAKE_V3);
    }

    function runKyberElastic() external {
        _upgradeAdapter(_deployments().getKyberElasticAdapter(), "KyberElasticAdapter", ADAPTER_KYBER);
    }

    function runKyberElastic(address adapterProxy) external {
        _upgradeAdapter(adapterProxy, "KyberElasticAdapter", ADAPTER_KYBER);
    }

    function runUniswapV4() external {
        _upgradeAdapter(_deployments().getUniswapV4Adapter(), "UniswapV4Adapter", ADAPTER_UNISWAP_V4);
    }

    function runUniswapV4(address adapterProxy) external {
        _upgradeAdapter(adapterProxy, "UniswapV4Adapter", ADAPTER_UNISWAP_V4);
    }

    function runWNative() external {
        _upgradeAdapter(_deployments().getWNativeAdapter(), "WNativeAdapter", ADAPTER_WNATIVE);
    }

    function runWNative(address adapterProxy) external {
        _upgradeAdapter(adapterProxy, "WNativeAdapter", ADAPTER_WNATIVE);
    }

    function runKuru() external {
        _upgradeAdapter(_deployments().getKuruAdapter(), "KuruAdapter", ADAPTER_KURU);
    }

    function runKuru(address adapterProxy) external {
        _upgradeAdapter(adapterProxy, "KuruAdapter", ADAPTER_KURU);
    }

    function _upgradeAdapter(address adapterProxy, string memory adapterName, uint8 adapterType) internal {
        INetworkDeployments deployments = _deployments();

        uint256 upgradeGasLimit = vm.envOr("ADAPTER_UPGRADE_GAS_LIMIT", uint256(200_000));
        require(adapterProxy != address(0), "UpgradeAdapters: adapter proxy not configured");

        console.log("Network:", deployments.getNetworkName());
        console.log("Adapter:", adapterName);
        console.log("Adapter proxy:", adapterProxy);
        console.log("Upgrade gas limit:", upgradeGasLimit);

        vm.startBroadcast();

        address newImplementation = _deployImplementation(adapterType);
        UniswapV2Adapter(payable(adapterProxy)).upgradeTo{gas: upgradeGasLimit}(newImplementation);

        vm.stopBroadcast();

        console.log("New adapter implementation:", newImplementation);
        console.log("Adapter upgraded successfully");
    }

    function _deployments() internal returns (INetworkDeployments) {
        DeploymentFactory factory = new DeploymentFactory();
        return factory.getDeployments();
    }

    function _deployImplementation(uint8 adapterType) internal returns (address implementation) {
        if (adapterType == ADAPTER_UNISWAP_V2) {
            implementation = address(new UniswapV2Adapter());
        } else if (adapterType == ADAPTER_UNISWAP_V3) {
            implementation = address(new UniswapV3Adapter());
        } else if (adapterType == ADAPTER_SUSHI_V3) {
            implementation = address(new SushiV3Adapter());
        } else if (adapterType == ADAPTER_PANCAKE_V3) {
            implementation = address(new PancakeV3Adapter());
        } else if (adapterType == ADAPTER_KYBER) {
            implementation = address(new KyberElasticAdapter());
        } else if (adapterType == ADAPTER_UNISWAP_V4) {
            implementation = address(new UniswapV4Adapter());
        } else if (adapterType == ADAPTER_WNATIVE) {
            implementation = address(new WNativeAdapter());
        } else if (adapterType == ADAPTER_KURU) {
            implementation = address(new KuruAdapter());
        } else {
            revert("UpgradeAdapters: unsupported adapter type");
        }
    }
}
