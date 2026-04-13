// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../../src/MoksaRouter.sol";
import "../../src/FeeVault.sol";
import "../../src/MoksaStaking.sol";
import "../../src/adapters/UniswapV2Adapter.sol";
import "../../src/adapters/UniswapV3Adapter.sol";
import "../../src/adapters/SushiV3Adapter.sol";
import "../../src/adapters/PancakeV3Adapter.sol";
import "../../src/adapters/KyberElasticAdapter.sol";
import "../../src/adapters/UniswapV4Adapter.sol";
import "../../src/adapters/WNativeAdapter.sol";
import "../../src/adapters/KuruAdapter.sol";
import "../../src/utils/UniswapV3StaticQuoter.sol";
import "../../src/utils/UniswapV4StaticQuoter.sol";

contract DeployUpgradeable is Script {
    function runRouter(string calldata prefix) external {
        vm.startBroadcast();

        address implementation = address(new MoksaRouter());
        address maintainer = vm.envAddress(_key(prefix, "INITIAL_MAINTAINER"));
        address feeClaimer = vm.envAddress(_key(prefix, "FEE_CLAIMER"));
        address wrappedNative = vm.envAddress(_key(prefix, "WRAPPED_NATIVE"));
        address[] memory adapters = _readAddressArray(_key(prefix, "ROUTER_INITIAL_ADAPTER"));
        address[] memory trustedTokens = _readAddressArray(_key(prefix, "ROUTER_TRUSTED_TOKEN"));

        bytes memory initData = abi.encodeCall(
            MoksaRouter.initialize,
            (adapters, trustedTokens, feeClaimer, wrappedNative, maintainer)
        );
        address proxy = _deployProxy(implementation, initData);
        _configureRouter(prefix, MoksaRouter(payable(proxy)));

        console.log("MoksaRouter implementation:", implementation);
        console.log("MoksaRouter proxy:", proxy);

        vm.stopBroadcast();
    }

    function runFeeVault(string calldata prefix) external {
        vm.startBroadcast();

        address implementation = address(new FeeVault());
        bytes memory initData = abi.encodeCall(
            FeeVault.initialize,
            (
                vm.envOr(_key(prefix, "FEE_VAULT_ROUTER"), address(0)),
                vm.envOr(_key(prefix, "FEE_VAULT_EXECUTOR"), address(0)),
                vm.envAddress(_key(prefix, "USDC")),
                vm.envAddress(_key(prefix, "INITIAL_MAINTAINER")),
                vm.envOr(_key(prefix, "RECOVERY_RECIPIENT"), address(0)),
                vm.envOr(_key(prefix, "RECOVERY_CAP_USDC"), uint256(0)),
                vm.envOr(_key(prefix, "DEVELOPMENT_RECIPIENT"), address(0)),
                vm.envOr(_key(prefix, "DEVELOPMENT_CAP_USDC"), uint256(0)),
                vm.envOr(_key(prefix, "POST_CAP_COMPANY_RECIPIENT"), address(0)),
                vm.envOr(_key(prefix, "PROTOCOL_RECIPIENT"), address(0)),
                vm.envOr(_key(prefix, "POST_CAP_COMPANY_BPS"), uint256(0))
            )
        );
        address proxy = _deployProxy(implementation, initData);
        _configureFeeVault(prefix, FeeVault(payable(proxy)));

        console.log("FeeVault implementation:", implementation);
        console.log("FeeVault proxy:", proxy);

        vm.stopBroadcast();
    }

    function runStaking(string calldata prefix) external {
        vm.startBroadcast();

        address implementation = address(new MoksaStaking());
        bytes memory initData = abi.encodeCall(
            MoksaStaking.initialize,
            (
                vm.envAddress(_key(prefix, "STAKING_TOKEN")),
                vm.envAddress(_key(prefix, "STAKING_REWARD_TOKEN")),
                vm.envUint(_key(prefix, "STAKING_UNBONDING_PERIOD")),
                vm.envAddress(_key(prefix, "INITIAL_MAINTAINER"))
            )
        );
        address proxy = _deployProxy(implementation, initData);

        console.log("MoksaStaking implementation:", implementation);
        console.log("MoksaStaking proxy:", proxy);

        vm.stopBroadcast();
    }

    function runUniswapV2(string calldata prefix) external {
        vm.startBroadcast();

        address implementation = address(new UniswapV2Adapter());
        bytes memory initData = abi.encodeCall(
            UniswapV2Adapter.initialize,
            (
                vm.envString(_key(prefix, "UNIV2_NAME")),
                vm.envAddress(_key(prefix, "UNIV2_FACTORY")),
                vm.envOr(_key(prefix, "UNIV2_FEE_BPS"), uint256(3)),
                vm.envOr(_key(prefix, "UNIV2_GAS_ESTIMATE"), uint256(150_000)),
                vm.envAddress(_key(prefix, "INITIAL_MAINTAINER"))
            )
        );
        address proxy = _deployProxy(implementation, initData);

        console.log("UniswapV2Adapter implementation:", implementation);
        console.log("UniswapV2Adapter proxy:", proxy);

        vm.stopBroadcast();
    }

    function runUniswapV3(string calldata prefix) external {
        vm.startBroadcast();

        address implementation = address(new UniswapV3Adapter());
        uint24[] memory defaultFees = _readUint24Array(_key(prefix, "UNIV3_DEFAULT_FEE"));
        if (defaultFees.length == 0) {
            defaultFees = _defaultUniswapV3Fees();
        }
        bytes memory initData = abi.encodeCall(
            UniswapV3Adapter.initialize,
            (
                vm.envString(_key(prefix, "UNIV3_NAME")),
                vm.envOr(_key(prefix, "UNIV3_GAS_ESTIMATE"), uint256(185_000)),
                vm.envOr(_key(prefix, "UNIV3_QUOTER_GAS_LIMIT"), uint256(500_000)),
                vm.envAddress(_key(prefix, "UNIV3_QUOTER")),
                vm.envAddress(_key(prefix, "UNIV3_FACTORY")),
                defaultFees,
                vm.envAddress(_key(prefix, "INITIAL_MAINTAINER"))
            )
        );
        address proxy = _deployProxy(implementation, initData);

        console.log("UniswapV3Adapter implementation:", implementation);
        console.log("UniswapV3Adapter proxy:", proxy);

        vm.stopBroadcast();
    }

    function runSushiV3(string calldata prefix) external {
        vm.startBroadcast();

        address implementation = address(new SushiV3Adapter());
        uint24[] memory defaultFees = _readUint24Array(_key(prefix, "SUSHIV3_DEFAULT_FEE"));
        if (defaultFees.length == 0) {
            defaultFees = _defaultUniswapV3Fees();
        }
        bytes memory initData = abi.encodeCall(
            SushiV3Adapter.initialize,
            (
                vm.envString(_key(prefix, "SUSHIV3_NAME")),
                vm.envOr(_key(prefix, "SUSHIV3_GAS_ESTIMATE"), uint256(185_000)),
                vm.envOr(_key(prefix, "SUSHIV3_QUOTER_GAS_LIMIT"), uint256(500_000)),
                vm.envAddress(_key(prefix, "SUSHIV3_QUOTER")),
                vm.envAddress(_key(prefix, "SUSHIV3_FACTORY")),
                defaultFees,
                vm.envAddress(_key(prefix, "INITIAL_MAINTAINER"))
            )
        );
        address proxy = _deployProxy(implementation, initData);

        console.log("SushiV3Adapter implementation:", implementation);
        console.log("SushiV3Adapter proxy:", proxy);

        vm.stopBroadcast();
    }

    function runPancakeV3(string calldata prefix) external {
        vm.startBroadcast();

        address implementation = address(new PancakeV3Adapter());
        uint24[] memory defaultFees = _readUint24Array(_key(prefix, "PANCAKEV3_DEFAULT_FEE"));
        if (defaultFees.length == 0) {
            defaultFees = _defaultPancakeV3Fees();
        }
        bytes memory initData = abi.encodeCall(
            PancakeV3Adapter.initialize,
            (
                vm.envString(_key(prefix, "PANCAKEV3_NAME")),
                vm.envOr(_key(prefix, "PANCAKEV3_GAS_ESTIMATE"), uint256(185_000)),
                vm.envOr(_key(prefix, "PANCAKEV3_QUOTER_GAS_LIMIT"), uint256(1_500_000)),
                vm.envAddress(_key(prefix, "PANCAKEV3_QUOTER")),
                vm.envAddress(_key(prefix, "PANCAKEV3_FACTORY")),
                defaultFees,
                vm.envAddress(_key(prefix, "INITIAL_MAINTAINER"))
            )
        );
        address proxy = _deployProxy(implementation, initData);

        console.log("PancakeV3Adapter implementation:", implementation);
        console.log("PancakeV3Adapter proxy:", proxy);

        vm.stopBroadcast();
    }

    function runKyberElastic(string calldata prefix) external {
        vm.startBroadcast();

        address implementation = address(new KyberElasticAdapter());
        bytes memory initData = abi.encodeCall(
            KyberElasticAdapter.initialize,
            (
                vm.envString(_key(prefix, "KYBER_NAME")),
                vm.envOr(_key(prefix, "KYBER_GAS_ESTIMATE"), uint256(220_000)),
                vm.envOr(_key(prefix, "KYBER_QUOTER_GAS_LIMIT"), uint256(1_500_000)),
                vm.envAddress(_key(prefix, "KYBER_QUOTER")),
                _readAddressArray(_key(prefix, "KYBER_POOL")),
                vm.envAddress(_key(prefix, "INITIAL_MAINTAINER"))
            )
        );
        address proxy = _deployProxy(implementation, initData);

        console.log("KyberElasticAdapter implementation:", implementation);
        console.log("KyberElasticAdapter proxy:", proxy);

        vm.stopBroadcast();
    }

    function runUniswapV4(string calldata prefix) external {
        vm.startBroadcast();

        address implementation = address(new UniswapV4Adapter());
        bytes memory initData = abi.encodeCall(
            UniswapV4Adapter.initialize,
            (
                vm.envString(_key(prefix, "UNIV4_NAME")),
                vm.envOr(_key(prefix, "UNIV4_GAS_ESTIMATE"), uint256(200_000)),
                vm.envAddress(_key(prefix, "UNIV4_STATIC_QUOTER")),
                vm.envAddress(_key(prefix, "UNIV4_POOL_MANAGER")),
                vm.envAddress(_key(prefix, "WRAPPED_NATIVE")),
                vm.envAddress(_key(prefix, "INITIAL_MAINTAINER"))
            )
        );
        address proxy = _deployProxy(implementation, initData);

        console.log("UniswapV4Adapter implementation:", implementation);
        console.log("UniswapV4Adapter proxy:", proxy);

        vm.stopBroadcast();
    }

    function runWNative(string calldata prefix) external {
        vm.startBroadcast();

        address implementation = address(new WNativeAdapter());
        bytes memory initData = abi.encodeCall(
            WNativeAdapter.initialize,
            (
                vm.envAddress(_key(prefix, "WRAPPED_NATIVE")),
                vm.envOr(_key(prefix, "WNATIVE_GAS_ESTIMATE"), uint256(80_000)),
                vm.envAddress(_key(prefix, "INITIAL_MAINTAINER"))
            )
        );
        address proxy = _deployProxy(implementation, initData);

        console.log("WNativeAdapter implementation:", implementation);
        console.log("WNativeAdapter proxy:", proxy);

        vm.stopBroadcast();
    }

    function runKuru(string calldata prefix) external {
        vm.startBroadcast();

        address implementation = address(new KuruAdapter());
        bytes memory initData = abi.encodeCall(
            KuruAdapter.initialize,
            (
                vm.envString(_key(prefix, "KURU_NAME")),
                vm.envOr(_key(prefix, "KURU_GAS_ESTIMATE"), uint256(300_000)),
                vm.envAddress(_key(prefix, "WRAPPED_NATIVE")),
                vm.envAddress(_key(prefix, "AUSD")),
                vm.envAddress(_key(prefix, "USDC")),
                vm.envAddress(_key(prefix, "KURU_MON_AUSD_MARKET")),
                vm.envAddress(_key(prefix, "KURU_MON_USDC_MARKET")),
                vm.envAddress(_key(prefix, "INITIAL_MAINTAINER"))
            )
        );
        address proxy = _deployProxy(implementation, initData);

        console.log("KuruAdapter implementation:", implementation);
        console.log("KuruAdapter proxy:", proxy);

        vm.stopBroadcast();
    }

    function runUniswapV3StaticQuoter() external {
        vm.startBroadcast();
        address quoter = address(new UniswapV3StaticQuoter());
        console.log("UniswapV3StaticQuoter:", quoter);
        vm.stopBroadcast();
    }

    function runUniswapV4StaticQuoter(string calldata prefix) external {
        vm.startBroadcast();
        address quoter = address(new UniswapV4StaticQuoter(vm.envAddress(_key(prefix, "UNIV4_POOL_MANAGER"))));
        console.log("UniswapV4StaticQuoter:", quoter);
        vm.stopBroadcast();
    }

    function _deployProxy(address implementation, bytes memory initData) internal returns (address) {
        ERC1967Proxy proxy = new ERC1967Proxy(implementation, initData);
        return address(proxy);
    }

    function _configureRouter(string calldata prefix, MoksaRouter router) internal {
        address operationsFeeClaimer = vm.envOr(_key(prefix, "OPERATIONS_FEE_CLAIMER"), address(0));
        if (operationsFeeClaimer != address(0)) {
            router.setOperationsFeeClaimer(operationsFeeClaimer);
        }

        address feeVault = vm.envOr(_key(prefix, "FEE_VAULT"), address(0));
        if (feeVault != address(0)) {
            router.setFeeVault(feeVault);
        }

        uint256 minFee = vm.envOr(_key(prefix, "ROUTER_MIN_FEE"), uint256(0));
        if (minFee > 0) {
            router.setMinFee(minFee);
        }

        uint256 operationsFeeBps = vm.envOr(_key(prefix, "OPERATIONS_FEE_BPS"), uint256(0));
        if (operationsFeeBps > 0) {
            router.setOperationsFeeBps(operationsFeeBps);
        }
    }

    function _configureFeeVault(string calldata prefix, FeeVault feeVault) internal {
        address router = vm.envOr(_key(prefix, "FEE_VAULT_ROUTER"), address(0));
        if (router != address(0)) {
            feeVault.setRouter(router);
        }

        address executor = vm.envOr(_key(prefix, "FEE_VAULT_EXECUTOR"), address(0));
        if (executor != address(0)) {
            feeVault.setExecutor(executor);
        }

        address recoveryRecipient = vm.envOr(_key(prefix, "RECOVERY_RECIPIENT"), address(0));
        if (recoveryRecipient != address(0)) {
            feeVault.setRecoveryRecipient(recoveryRecipient);
        }

        uint256 recoveryCapUsdc = vm.envOr(_key(prefix, "RECOVERY_CAP_USDC"), uint256(0));
        if (recoveryCapUsdc > 0) {
            feeVault.setRecoveryCapUsdc(recoveryCapUsdc);
        }

        address developmentRecipient = vm.envOr(_key(prefix, "DEVELOPMENT_RECIPIENT"), address(0));
        if (developmentRecipient != address(0)) {
            feeVault.setDevelopmentRecipient(developmentRecipient);
        }

        uint256 developmentCapUsdc = vm.envOr(_key(prefix, "DEVELOPMENT_CAP_USDC"), uint256(0));
        if (developmentCapUsdc > 0) {
            feeVault.setDevelopmentCapUsdc(developmentCapUsdc);
        }

        address postCapCompanyRecipient = vm.envOr(_key(prefix, "POST_CAP_COMPANY_RECIPIENT"), address(0));
        if (postCapCompanyRecipient != address(0)) {
            feeVault.setPostCapCompanyRecipient(postCapCompanyRecipient);
        }

        address protocolRecipient = vm.envOr(_key(prefix, "PROTOCOL_RECIPIENT"), address(0));
        if (protocolRecipient != address(0)) {
            feeVault.setProtocolRecipient(protocolRecipient);
        }

        uint256 postCapCompanyBps = vm.envOr(_key(prefix, "POST_CAP_COMPANY_BPS"), uint256(0));
        if (postCapCompanyBps > 0) {
            feeVault.setPostCapCompanyBps(postCapCompanyBps);
        }
    }

    function _key(string memory prefix, string memory suffix) internal pure returns (string memory) {
        return string.concat(prefix, "_", suffix);
    }

    function _readAddressArray(string memory baseKey) internal view returns (address[] memory values) {
        uint256 count = vm.envOr(string.concat(baseKey, "_COUNT"), uint256(0));
        values = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            values[i] = vm.envAddress(string.concat(baseKey, "_", vm.toString(i)));
        }
    }

    function _readUint24Array(string memory baseKey) internal view returns (uint24[] memory values) {
        uint256 count = vm.envOr(string.concat(baseKey, "_COUNT"), uint256(0));
        values = new uint24[](count);
        for (uint256 i = 0; i < count; i++) {
            values[i] = uint24(vm.envUint(string.concat(baseKey, "_", vm.toString(i))));
        }
    }

    function _defaultUniswapV3Fees() internal pure returns (uint24[] memory values) {
        values = new uint24[](4);
        values[0] = 100;
        values[1] = 500;
        values[2] = 3000;
        values[3] = 10_000;
    }

    function _defaultPancakeV3Fees() internal pure returns (uint24[] memory values) {
        values = new uint24[](3);
        values[0] = 100;
        values[1] = 500;
        values[2] = 10_000;
    }
}
