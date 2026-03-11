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
- `<PREFIX>_PK_DEPLOYER` for any broadcasted action through the interactive menu

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

## Interactive contract menu

Use the interactive wrapper for deployments, upgrades, admin changes, and read-only inspection:

```bash
./script/deploy/interactive.sh
```

The menu is grouped to keep actions manageable:

- `deploy` - deploy router, adapters, and the V3 static quoter
- `upgrade` - upgrade existing proxy contracts
- `admin` - apply on-chain config changes
- `inspect` - run read-only checks

Typical flow:

1. Choose network (`monad` or `sepolia`)
2. Choose action group
3. Choose the specific action
4. Confirm broadcast if the action mutates state

If you confirm broadcast, the script reads the private key from `<PREFIX>_PK_DEPLOYER` in `.env`.

### Router fee management

The interactive script now includes dedicated router fee operations under `admin`:

- `router-fee-status`
- `router-native-balance`
- `router-token-balance`
- `router-set-hold-fees`
- `router-set-fee-claimer`
- `router-claim-fees`

These actions are backed by `script/admin/ManageRouterFees.s.sol`.

Direct examples:

```bash
forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees \
  --sig "runStatus()" \
  --rpc-url monad

forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees \
  --sig "runSetHoldFees(bool)" true \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast

forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees \
  --sig "runTokenBalance(address)" \
  0xYourToken \
  --rpc-url monad

forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees \
  --sig "runClaimFees(address,address,uint256)" \
  0x0000000000000000000000000000000000000000 \
  0xYourRecipient \
  1000000000000000000 \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast
```

Notes:

- Use the zero address as the token when claiming native fees.
- For native-entry swaps, retained fees are usually held as wrapped native in the router.
- Use `router-token-balance` for ERC20 balances and `router-native-balance` for raw native balance.

### Router upgrade + fee hold enable flow

To enable retained router fees on an existing deployment:

1. Run `upgrade -> router` from `./script/deploy/interactive.sh`
2. Run `admin -> router-set-hold-fees`
3. Later, run `admin -> router-claim-fees` to move accrued balances out

## Admin scripts

These scripts now work for any supported network via `DeploymentFactory`:

```bash
forge script script/admin/ListAdapters.s.sol --rpc-url sepolia
forge script script/admin/UpgradeRouter.s.sol --rpc-url sepolia --broadcast
forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees --sig "runStatus()" --rpc-url sepolia
forge script script/admin/UpdateAdapters.s.sol --account deployer --rpc-url sepolia --broadcast
forge script script/admin/UpdateHopTokens.s.sol --account deployer --rpc-url sepolia --broadcast
forge script script/admin/ManageUniswapV4Pools.s.sol --account deployer --rpc-url sepolia --broadcast
```
