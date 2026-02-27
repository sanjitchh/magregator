# Moksa Aggregator

Moksa Aggregator is a smart-contract DEX aggregator focused on Monad.

## Current scope

- Primary network: Monad (`chainId` 143 / 10143)
- Router: `MoksaRouter`
- Active Monad adapters:
  - `UniswapV2Adapter`
  - `UniswapV3Adapter`
  - `PancakeV3Adapter`
  - `KuruAdapter`
  - `UniswapV4Adapter`
  - `KyberElasticAdapter`
  - `WNativeAdapter`

## Architecture

Core contracts:

- `src/MoksaRouter.sol`
- `src/MoksaAdapter.sol`
- `src/interface/IMoksaRouter.sol`
- `src/lib/MoksaViewUtils.sol`

Network deployment registry:

- `deployments/MonadDeployments.sol`
- `deployments/utils/DeploymentFactory.sol`

## Setup

```bash
cp .env.sample .env
```

Set Monad variables in `.env`:

- `MONAD_RPC`
- `MONAD_UNIV2_FACTORY`
- `MONAD_UNIV3_FACTORY`
- `MONAD_UNIV3_QUOTER`
- `MONAD_PANCAKEV3_FACTORY`
- `MONAD_PANCAKEV3_QUOTER`
- `MONAD_PANCAKEV3_QUOTER_GAS_LIMIT`
- `MONAD_PANCAKEV3_GAS_ESTIMATE`
- `MONAD_AUSD`
- `MONAD_USDC`
- `MONAD_KURU_MON_AUSD_MARKET`
- `MONAD_KURU_MON_USDC_MARKET`
- `MONAD_KURU_GAS_ESTIMATE`
- `MONAD_UNIV4_POOL_MANAGER`
- `MONAD_UNIV4_STATIC_QUOTER`
- `MONAD_UNIV4_GAS_ESTIMATE`
- `MONAD_WRAPPED_NATIVE`
- `MONAD_KYBER_QUOTER`
- `MONAD_KYBER_QUOTER_GAS_LIMIT`
- `MONAD_KYBER_GAS_ESTIMATE`
- `MONAD_KYBER_POOL_COUNT`
- `MONAD_KYBER_POOL_0 ... MONAD_KYBER_POOL_N`

## Deploy scripts (Monad)

- `script/deploy/DeployMonadUniswapV2Adapter.s.sol`
- `script/deploy/DeployMonadUniswapV3Adapter.s.sol`
- `script/deploy/DeployMonadPancakeV3Adapter.s.sol`
- `script/deploy/DeployMonadKuruAdapter.s.sol`
- `script/deploy/DeployMonadUniswapV4Adapter.s.sol`
- `script/deploy/DeployMonadKyberElasticAdapter.s.sol`
- `script/deploy/DeployMonadWNativeAdapter.s.sol`

Example:

```bash
forge script script/deploy/DeployMonadUniswapV4Adapter.s.sol:DeployMonadUniswapV4Adapter --account deployer --rpc-url monad --broadcast
```

## Admin scripts

- List adapters:

```bash
forge script script/admin/ListAdapters.s.sol --rpc-url monad
```

- Sync adapters from deployment registry:

```bash
forge script script/admin/UpdateAdapters.s.sol --account deployer --rpc-url monad --broadcast
```

- Sync trusted hop tokens:

```bash
forge script script/admin/UpdateHopTokens.s.sol --account deployer --rpc-url monad --broadcast
```

- Manage Uniswap V4 pools:

```bash
forge script script/admin/ManageUniswapV4Pools.s.sol --account deployer --rpc-url monad --broadcast
```

## Future expansion

The codebase is intentionally kept modular to add more networks later (including Ethereum mainnet) by introducing new deployment configs under `deployments/` and wiring them in `DeploymentFactory`.
