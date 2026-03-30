// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

import {AdapterTestBase} from "./AdapterTestBase.sol";
import {UniswapV2Adapter} from "../src/adapters/UniswapV2Adapter.sol";
import {PancakeV3Adapter} from "../src/adapters/PancakeV3Adapter.sol";
import {KyberElasticAdapter} from "../src/adapters/KyberElasticAdapter.sol";
import {SushiV3Adapter} from "../src/adapters/SushiV3Adapter.sol";
import {UniswapV4Adapter} from "../src/adapters/UniswapV4Adapter.sol";
import {UniswapV3StaticQuoter} from "../src/utils/UniswapV3StaticQuoter.sol";
import {UniswapV4StaticQuoter} from "../src/utils/UniswapV4StaticQuoter.sol";
import {IUniswapV4StaticQuoter} from "../src/interface/IUniswapV4StaticQuoter.sol";

contract EthereumMainnetAdapterForkTest is AdapterTestBase {
    using PoolIdLibrary for PoolKey;

    string internal constant DEFAULT_ETHEREUM_RPC = "https://ethereum.publicnode.com";

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address internal constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address internal constant PANCAKE_V3_FACTORY = 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865;
    address internal constant SUSHI_V3_FACTORY = 0xbACEB8eC6b9355Dfc0269C18bac9d6E2Bdc29C4F;
    address internal constant KYBER_QUOTER_V2 = 0x4d47fd5a29904Dae0Ef51b1c450C9750F15D7856;
    address internal constant KYBER_FACTORY = 0xC7a590291e07B9fe9E64b86c58fD8fC764308C4A;
    address internal constant UNISWAP_V4_POOL_MANAGER = 0x000000000004444c5dc75cB358380D2e3dE08A90;

    uint24 internal constant KYBER_WETH_USDC_FEE = 100;
    uint256 internal constant AMOUNT_IN = 0.01 ether;

    function setUp() external {
        vm.createSelectFork(_ethereumRpcUrl());
    }

    function testUniswapV2MainnetForkSwapMatchesQuery() external {
        UniswapV2Adapter adapter = _deployUniswapV2Adapter();
        assertSwapMatchesQuery(adapter, WETH, USDC, AMOUNT_IN, 0.02e18);
    }

    function testPancakeV3MainnetForkStaticQuoterQuotesKnownPool() external {
        UniswapV3StaticQuoter quoter = new UniswapV3StaticQuoter();
        address pool = _pancakePool(WETH, USDC, 500);
        (int256 amount0, int256 amount1) = quoter.quote(pool, false, int256(AMOUNT_IN), 0);

        assertEq(amount1, int256(AMOUNT_IN), "Pancake static quoter should preserve input amount");
        assertLt(amount0, 0, "Pancake static quoter should return token0 out");
    }

    function testPancakeV3MainnetForkSwapMatchesQuery() external {
        PancakeV3Adapter adapter = _deployPancakeV3Adapter();
        assertSwapMatchesQuery(adapter, WETH, USDC, AMOUNT_IN, 0.03e18);
    }

    function testSushiV3MainnetForkSwapMatchesQuery() external {
        SushiV3Adapter adapter = _deploySushiV3Adapter();
        assertSwapMatchesQuery(adapter, WETH, USDC, AMOUNT_IN, 0.03e18);
    }

    function testUniswapV4MainnetForkDiscoversMainnetPools() external view {
        PoolKey[] memory pools = _discoverCanonicalUniswapV4Pools(WETH, USDC);
        assertGt(pools.length, 0, "Expected to find at least one mainnet UniswapV4 WETH/USDC pool");
    }

    function testUniswapV4MainnetForkStaticQuoterQuotesKnownPool() external {
        PoolKey[] memory pools = _discoverCanonicalUniswapV4Pools(WETH, USDC);
        require(pools.length != 0, "No mainnet UniswapV4 pools found for WETH/USDC");

        UniswapV4StaticQuoter quoter = new UniswapV4StaticQuoter(UNISWAP_V4_POOL_MANAGER);
        uint256 quote = quoter.quoteExactInputSingle(
            IUniswapV4StaticQuoter.QuoteExactInputSingleParams({
                poolKey: pools[0],
                zeroForOne: Currency.unwrap(pools[0].currency0) == WETH,
                amountIn: uint128(AMOUNT_IN),
                sqrtPriceLimitX96: 0,
                hookData: ""
            })
        );

        assertGt(quote, 0, "Expected a non-zero UniswapV4 quote");
    }

    function testUniswapV4MainnetForkSwapMatchesQuery() external {
        UniswapV4Adapter adapter = _deployUniswapV4Adapter();

        PoolKey[] memory pools = _discoverCanonicalUniswapV4Pools(WETH, USDC);
        require(pools.length != 0, "No mainnet UniswapV4 pools found for WETH/USDC");

        adapter.addPool(pools[0]);

        assertSwapMatchesQuery(adapter, WETH, USDC, AMOUNT_IN, 0.03e18);
    }

    function testKyberMainnetForkCurrentConfigDoesNotProduceQuote() external {
        KyberElasticAdapter adapter = _deployKyberElasticAdapter();

        uint256 amountOut = adapter.query(AMOUNT_IN, WETH, USDC);

        assertEq(amountOut, 0, "Current Kyber adapter unexpectedly quoted on mainnet");
    }

    function testKyberMainnetForkQuoterUsesDifferentInterface() external view {
        address pool = _kyberPool(WETH, USDC, KYBER_WETH_USDC_FEE);
        assertTrue(pool != address(0), "Expected to find a mainnet Kyber WETH/USDC pool");

        bytes4 legacySelector = bytes4(keccak256("quote(address,bool,int256,uint160)"));
        bytes memory legacyCall = abi.encodeWithSelector(
            legacySelector,
            pool,
            false,
            int256(AMOUNT_IN),
            uint160(type(uint160).max - 1)
        );

        (bool legacySuccess,) = KYBER_QUOTER_V2.staticcall(legacyCall);
        assertFalse(legacySuccess, "Kyber mainnet quoter should not support legacy quote interface");
    }

    function _deployUniswapV2Adapter() internal returns (UniswapV2Adapter) {
        UniswapV2Adapter implementation = new UniswapV2Adapter();
        bytes memory initData = abi.encodeCall(
            UniswapV2Adapter.initialize, ("EthereumUniswapV2Adapter", UNISWAP_V2_FACTORY, 3, 150_000, address(this))
        );
        return UniswapV2Adapter(payable(address(new ERC1967Proxy(address(implementation), initData))));
    }

    function _deployPancakeV3Adapter() internal returns (PancakeV3Adapter) {
        PancakeV3Adapter implementation = new PancakeV3Adapter();
        UniswapV3StaticQuoter quoter = new UniswapV3StaticQuoter();

        uint24[] memory fees = new uint24[](4);
        fees[0] = 100;
        fees[1] = 500;
        fees[2] = 2500;
        fees[3] = 10_000;

        bytes memory initData = abi.encodeCall(
            PancakeV3Adapter.initialize,
            ("EthereumPancakeV3Adapter", 185_000, 1_500_000, address(quoter), PANCAKE_V3_FACTORY, fees, address(this))
        );

        return PancakeV3Adapter(payable(address(new ERC1967Proxy(address(implementation), initData))));
    }

    function _deploySushiV3Adapter() internal returns (SushiV3Adapter) {
        SushiV3Adapter implementation = new SushiV3Adapter();
        UniswapV3StaticQuoter quoter = new UniswapV3StaticQuoter();

        uint24[] memory fees = new uint24[](4);
        fees[0] = 100;
        fees[1] = 500;
        fees[2] = 3000;
        fees[3] = 10_000;

        bytes memory initData = abi.encodeCall(
            SushiV3Adapter.initialize,
            ("EthereumSushiV3Adapter", 185_000, 500_000, address(quoter), SUSHI_V3_FACTORY, fees, address(this))
        );

        return SushiV3Adapter(payable(address(new ERC1967Proxy(address(implementation), initData))));
    }

    function _deployKyberElasticAdapter() internal returns (KyberElasticAdapter) {
        KyberElasticAdapter implementation = new KyberElasticAdapter();
        address[] memory pools = new address[](1);
        pools[0] = _kyberPool(WETH, USDC, KYBER_WETH_USDC_FEE);

        bytes memory initData = abi.encodeCall(
            KyberElasticAdapter.initialize,
            ("EthereumKyberElasticAdapter", 220_000, 1_500_000, KYBER_QUOTER_V2, pools, address(this))
        );

        return KyberElasticAdapter(payable(address(new ERC1967Proxy(address(implementation), initData))));
    }

    function _deployUniswapV4Adapter() internal returns (UniswapV4Adapter) {
        UniswapV4Adapter implementation = new UniswapV4Adapter();
        UniswapV4StaticQuoter quoter = new UniswapV4StaticQuoter(UNISWAP_V4_POOL_MANAGER);
        bytes memory initData = abi.encodeCall(
            UniswapV4Adapter.initialize,
            (
                "EthereumUniswapV4Adapter",
                200_000,
                address(quoter),
                UNISWAP_V4_POOL_MANAGER,
                WETH,
                address(this)
            )
        );

        return UniswapV4Adapter(payable(address(new ERC1967Proxy(address(implementation), initData))));
    }

    function _discoverCanonicalUniswapV4Pools(address token0, address token1)
        internal
        view
        returns (PoolKey[] memory finalPools)
    {
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
        }

        uint24[] memory fees = new uint24[](4);
        fees[0] = 3000;
        fees[1] = 500;
        fees[2] = 100;
        fees[3] = 10_000;

        int24[] memory tickSpacings = new int24[](4);
        tickSpacings[0] = 60;
        tickSpacings[1] = 10;
        tickSpacings[2] = 1;
        tickSpacings[3] = 200;

        PoolKey[] memory pools = new PoolKey[](fees.length);
        uint256 count;

        for (uint256 i = 0; i < fees.length; i++) {
            PoolKey memory poolKey = PoolKey({
                currency0: Currency.wrap(token0),
                currency1: Currency.wrap(token1),
                fee: fees[i],
                tickSpacing: tickSpacings[i],
                hooks: IHooks(address(0))
            });

            if (_uniswapV4PoolExists(poolKey)) {
                pools[count] = poolKey;
                count++;
            }
        }

        finalPools = new PoolKey[](count);
        for (uint256 i = 0; i < count; i++) {
            finalPools[i] = pools[i];
        }
    }

    function _uniswapV4PoolExists(PoolKey memory poolKey) internal view returns (bool) {
        PoolId poolId = poolKey.toId();
        (uint160 sqrtPriceX96,,,) = StateLibrary.getSlot0(IPoolManager(UNISWAP_V4_POOL_MANAGER), poolId);
        return sqrtPriceX96 != 0;
    }

    function _kyberPool(address tokenA, address tokenB, uint24 feeUnits) internal view returns (address) {
        return IKyberFactory(KYBER_FACTORY).getPool(tokenA, tokenB, feeUnits);
    }

    function _pancakePool(address tokenA, address tokenB, uint24 feeUnits) internal view returns (address) {
        return IPancakeV3Factory(PANCAKE_V3_FACTORY).getPool(tokenA, tokenB, feeUnits);
    }

    function _ethereumRpcUrl() internal view returns (string memory) {
        return vm.envOr("ETHEREUM_RPC", DEFAULT_ETHEREUM_RPC);
    }
}

interface IKyberFactory {
    function getPool(address tokenA, address tokenB, uint24 feeUnits) external view returns (address);
}

interface IPancakeV3Factory {
    function getPool(address tokenA, address tokenB, uint24 feeUnits) external view returns (address);
}
