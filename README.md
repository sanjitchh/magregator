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

Fresh router deployments also pick up optional fee-accounting settings from `.env` automatically. Supported keys are:

- `<PREFIX>_COMPANY_FEE_CLAIMER`
- `<PREFIX>_OPERATIONS_FEE_CLAIMER`
- `<PREFIX>_OPERATIONS_FEE_BPS`
- `<PREFIX>_COMPANY_PRE_CAP_ENABLED`
- `<PREFIX>_COMPANY_POST_CAP_FEE_BPS`
- `<PREFIX>_COMPANY_FEE_CAP_USD` (8 decimals, so `$50,000` = `5000000000000`)
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
- `router-set-fee-claimer`
- `router-set-company-fee-claimer`
- `router-set-operations-fee-claimer`
- `router-set-operations-fee-bps`
- `router-set-company-pre-cap-enabled`
- `router-set-company-post-cap-fee-bps`
- `router-set-company-fee-cap-usd`
- `router-set-price-feed`
- `router-set-price-feed-staleness`
- `router-claim-operations-fees`
- `router-claim-company-fees`
- `router-claim-protocol-fees`

These actions are backed by `script/admin/ManageRouterFees.s.sol`.

Direct examples:

```bash
forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees \
  --sig "runStatus()" \
  --rpc-url monad

forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees \
  --sig "runSetOperationsFeeBps(uint256)" 500 \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast

forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees \
  --sig "runSetCompanyFeeClaimer(address)" \
  0xYourCompanyFeeClaimer \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast

forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees \
  --sig "runSetCompanyFeeCapUsdWhole(uint256)" \
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
  --sig "runClaimOperationsFees(address,uint256)" \
  0xYourFeeToken \
  1000000 \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast

forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees \
  --sig "runClaimProtocolFees(address,uint256)" \
  0xYourFeeToken \
  1000000 \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast
```

Notes:

- For native-entry swaps, retained fees are usually held as wrapped native in the router.
- Use `router-token-balance` for ERC20 balances and bucket totals, and `router-native-balance` for raw native balance.

### Router fee buckets

The router now pays operations fees out immediately when `OPERATIONS_FEE_CLAIMER` is configured, and keeps the remaining fee inside the router in per-token buckets:

- A configurable operations slice is paid out first to `OPERATIONS_FEE_CLAIMER`.
- If `COMPANY_PRE_CAP_ENABLED` is on, then before the company USD cap is reached the remaining fee is reserved entirely for `COMPANY_FEE_CLAIMER`.
- When pre-cap mode is off, or once the cap is reached, the remaining fee is split and paid out immediately between `COMPANY_FEE_CLAIMER` and `FEE_CLAIMER` using configurable basis points.
- Tokens without a configured USD price feed still accrue token balances, but they do not advance the USD cap counter.
- If `OPERATIONS_FEE_CLAIMER` is unset, the operations slice stays claimable from the router as a fallback.
- If `COMPANY_FEE_CLAIMER` or `FEE_CLAIMER` is unset during immediate split payout, that share stays claimable from the router as a fallback.

The USD accounting uses 8 decimals internally. For example, `$50,000` is stored as `5000000000000`.

Recommended setup order:

1. `upgrade -> router`
2. `admin -> router-set-fee-claimer`
3. `admin -> router-set-company-fee-claimer`
4. `admin -> router-set-operations-fee-claimer`
5. `admin -> router-set-operations-fee-bps`
6. Optional: keep `admin -> router-set-company-pre-cap-enabled` enabled if you still want the company-only accrual phase
7. `admin -> router-set-company-post-cap-fee-bps`
8. `admin -> router-set-company-fee-cap-usd`
9. `admin -> router-set-price-feed` for every fee token that should count toward the company cap
10. Optional: `admin -> router-fee-usd-value` to verify feed configuration

### Router upgrade + claim flow

To enable retained router fee accounting on an existing deployment:

1. Run `upgrade -> router` from `./script/deploy/interactive.sh`
2. Configure the company, operations, cap, and price-feed settings under `admin`
3. Later, run `admin -> router-claim-company-fees` or `admin -> router-claim-protocol-fees` as needed for pre-cap/fallback balances; `router-claim-operations-fees` is only needed if the operations claimer was unset when fees were collected

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
