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

Fresh router deployments also pick up optional special-fee settings from `.env` automatically. Supported keys are:

- `<PREFIX>_DEPLOYER_REDEEMER`
- `<PREFIX>_ROUTER_HOLD_FEES`
- `<PREFIX>_SPECIAL_REDEEM_ENABLED`
- `<PREFIX>_SPECIAL_REDEEM_CAP_USD` (8 decimals, so `$50,000` = `5000000000000`)
- `<PREFIX>_PRICE_FEED_STALENESS`
- `<PREFIX>_ROUTER_FEE_PRICE_FEED_COUNT`
- `<PREFIX>_ROUTER_FEE_PRICE_FEED_TOKEN_<INDEX>`
- `<PREFIX>_ROUTER_FEE_PRICE_FEED_<INDEX>`

That means new router deployments can come up preconfigured without requiring separate post-deploy admin transactions.

### Router fee management

The interactive script now includes dedicated router fee operations under `admin`:

- `router-fee-status`
- `router-native-balance`
- `router-token-balance`
- `router-fee-usd-value`
- `router-set-hold-fees`
- `router-set-fee-claimer`
- `router-set-deployer-redeemer`
- `router-set-special-enabled`
- `router-set-special-cap-usd`
- `router-set-price-feed`
- `router-set-price-feed-staleness`
- `router-claim-fees`
- `router-claim-special-fees`

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
  --sig "runSetDeployerRedeemer(address)" \
  0xYourDeployerRedeemer \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast

forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees \
  --sig "runSetSpecialRedeemCapUsdWhole(uint256)" \
  50000 \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast

forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees \
  --sig "runSetFeePriceFeed(address,address)" \
  0xYourFeeToken \
  0xYourUsdPriceFeed \
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

forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees \
  --sig "runClaimSpecialFees(address,uint256)" \
  0xYourFeeToken \
  1000000 \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast
```

Notes:

- Use the zero address as the token when claiming native fees.
- For native-entry swaps, retained fees are usually held as wrapped native in the router.
- Use `router-token-balance` for ERC20 balances and `router-native-balance` for raw native balance.

### Special deployer redeem bucket

The router now supports an accrual-based special fee bucket:

- While the first `$50,000` of configured fee tokens is being accrued, those fees stay in the router.
- That reserved bucket can only be redeemed by the configured deployer redeemer.
- Once the `$50,000` cap has been fully accrued, new fees go directly to `FEE_CLAIMER`.
- Tokens without a configured USD price feed bypass the special bucket and go straight to `FEE_CLAIMER`.

The USD accounting uses 8 decimals internally. For example, `$50,000` is stored as `5000000000000`.

Recommended setup order:

1. `upgrade -> router`
2. `admin -> router-set-fee-claimer`
3. `admin -> router-set-deployer-redeemer`
4. `admin -> router-set-special-cap-usd`
5. `admin -> router-set-special-enabled`
6. `admin -> router-set-price-feed` for every fee token that should count toward the special bucket
7. Optional: `admin -> router-fee-usd-value` to verify feed configuration

### Router upgrade + fee hold enable flow

To enable retained router fees on an existing deployment:

1. Run `upgrade -> router` from `./script/deploy/interactive.sh`
2. Run `admin -> router-set-hold-fees` for legacy fee holding, or configure the special deployer redeem bucket if you want accrual-based routing
3. Later, run `admin -> router-claim-fees` or `admin -> router-claim-special-fees` as needed

## Admin scripts

These scripts now work for any supported network via `DeploymentFactory`:

```bash
forge script script/admin/ListAdapters.s.sol --rpc-url sepolia
forge script script/admin/CheckAdapterQuotes.s.sol:CheckAdapterQuotes \
  --sig "runPair(address,address,uint256)" \
  0xfff9976782d46cc05630d1f6ebab18b2324d6b14 \
  0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238 \
  1000000000000000000 \
  --rpc-url sepolia
forge script script/admin/UpgradeRouter.s.sol --rpc-url sepolia --broadcast
forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees --sig "runStatus()" --rpc-url sepolia
forge script script/admin/UpdateAdapters.s.sol --account deployer --rpc-url sepolia --broadcast
forge script script/admin/UpdateHopTokens.s.sol --account deployer --rpc-url sepolia --broadcast
forge script script/admin/ManageUniswapV4Pools.s.sol --account deployer --rpc-url sepolia --broadcast
```
