# Moksa Aggregator

Moksa Aggregator is a modular DEX-aggregation router with upgradeable router/adapters and multi-network deployment support.

## Networks

- Monad (`chainId` 143 / 10143)
- Ethereum Sepolia (`chainId` 11155111)

Network registry contracts:

- `deployments/MonadDeployments.sol`
- `deployments/SepoliaDeployments.sol`
- `deployments/utils/DeploymentFactory.sol`

## Upgradeability model

- Contracts use UUPS upgradeability with `ERC1967Proxy`.
- Implementation contracts are deployed once per component.
- Proxy is initialized during deployment.
- Upgrade authorization is controlled by `MAINTAINER_ROLE`.

## Setup

```bash
cp .env.sample .env
```

Fill the environment variables for your target network (`MONAD_*` or `SEPOLIA_*`).

Required baseline values:

- `<PREFIX>_RPC`
- `<PREFIX>_INITIAL_MAINTAINER`
- `<PREFIX>_FEE_CLAIMER`
- `<PREFIX>_WRAPPED_NATIVE`

## Common deploy script

Use one network-agnostic deployment script:

- `script/deploy/DeployUpgradeable.s.sol`

Available entrypoints:

- `runRouter(string)`
- `runUniswapV2(string)`
- `runUniswapV3(string)`
- `runPancakeV3(string)`
- `runKyberElastic(string)`
- `runUniswapV4(string)`
- `runWNative(string)`
- `runKuru(string)`

Example (Sepolia Uniswap V3 adapter):

```bash
forge script script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable \
  --sig "runUniswapV3(string)" SEPOLIA \
  --rpc-url sepolia \
  --account deployer \
  --broadcast
```

## Interactive deploy menu

Use the interactive wrapper to choose network + component:

```bash
./script/deploy/interactive.sh
```

The script prompts for:

- Network (`monad` or `sepolia`)
- Component (router/adapter)
- Broadcast mode

## Admin scripts

These scripts now work for any supported network via `DeploymentFactory`:

```bash
forge script script/admin/ListAdapters.s.sol --rpc-url sepolia
forge script script/admin/UpdateAdapters.s.sol --account deployer --rpc-url sepolia --broadcast
forge script script/admin/UpdateHopTokens.s.sol --account deployer --rpc-url sepolia --broadcast
forge script script/admin/ManageUniswapV4Pools.s.sol --account deployer --rpc-url sepolia --broadcast
```
