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

Fresh router deployments also pick up optional fee-routing settings from `.env` automatically. Supported keys are:

- `<PREFIX>_OPERATIONS_FEE_CLAIMER`
- `<PREFIX>_OPERATIONS_FEE_BPS`
- `<PREFIX>_FEE_VAULT`

Fresh fee vault deployments also pick up optional treasury settings from `.env` automatically. Supported keys are:

- `<PREFIX>_FEE_VAULT_ROUTER`
- `<PREFIX>_FEE_VAULT_EXECUTOR`
- `<PREFIX>_RECOVERY_RECIPIENT`
- `<PREFIX>_RECOVERY_CAP_USDC`
- `<PREFIX>_DEVELOPMENT_RECIPIENT`
- `<PREFIX>_DEVELOPMENT_CAP_USDC`
- `<PREFIX>_POST_CAP_COMPANY_RECIPIENT`
- `<PREFIX>_PROTOCOL_RECIPIENT`
- `<PREFIX>_POST_CAP_COMPANY_BPS`

`RECOVERY_CAP_USDC` and `DEVELOPMENT_CAP_USDC` use raw USDC base units. With 6-decimal USDC, `50,000 USDC` should be set as `50000000000`.

That means new router and fee vault deployments can come up preconfigured without requiring separate post-deploy admin transactions.

### Router fee management

The interactive script now groups `admin` actions into smaller submenus: `router-fees`, `fee-vault`, and `sync-tools`.

Under `admin -> router-fees` you can access:

- `router-fee-status`
- `router-native-balance`
- `router-token-balance`
- `router-set-fee-vault`
- `router-set-fee-claimer`
- `router-set-company-fee-claimer`
- `router-set-operations-fee-claimer`
- `router-set-operations-fee-bps`
- `router-claim-operations-fees`

These actions are backed by `script/admin/ManageRouterFees.s.sol`.
Legacy company/protocol claim helpers remain available in `script/admin/ManageRouterFees.s.sol` as
`runClaimLegacyCompanyFees` and `runClaimLegacyProtocolFees` for historical router balances only; they are not part of the
active fee-vault flow.

### Fee vault management

Under `admin -> fee-vault` you can access:

- `vault-status`
- `vault-token-balance`
- `vault-set-router`
- `vault-set-executor`
- `vault-set-usdc`
- `vault-set-recovery-recipient`
- `vault-set-recovery-cap-usdc`
- `vault-set-development-recipient`
- `vault-set-development-cap-usdc`
- `vault-set-postcap-company-recipient`
- `vault-set-protocol-recipient`
- `vault-set-postcap-company-bps`
- `vault-set-allowed-target`
- `vault-set-token-approval`
- `vault-distribute-pending-usdc`

These actions are backed by `script/admin/ManageFeeVault.s.sol`.

Under `admin -> sync-tools` you can access:

- `update-adapters`
- `update-hop-tokens`
- `manage-uniswapv4-pools`

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
  --sig "runSetFeeVault(address)" \
  0xYourFeeVault \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast

forge script script/admin/ManageFeeVault.s.sol:ManageFeeVault \
  --sig "runStatus()" \
  --rpc-url monad \

forge script script/admin/ManageFeeVault.s.sol:ManageFeeVault \
  --sig "runSetRecoveryCapUsdc(uint256)" \
  50000000000 \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast

forge script script/admin/ManageFeeVault.s.sol:ManageFeeVault \
  --sig "runSetAllowedSwapTarget(address,bool)" \
  0xYourSwapTarget \
  true \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast

forge script script/admin/ManageFeeVault.s.sol:ManageFeeVault \
  --sig "runSetTokenApproval(address,address,uint256)" \
  0xYourToken \
  0xYourSwapTarget \
  1000000000000000000 \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast

forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees \
  --sig "runClaimOperationsFees(address,uint256)" \
  0xYourFeeToken \
  1000000 \
  --rpc-url monad \
  --private-key "$MONAD_PK_DEPLOYER" \
  --broadcast
```

Notes:

- For native-entry swaps, retained fees are usually held as wrapped native in the router or fee vault.
- Use `router-token-balance` to inspect fallback balances left in the router.
- Use `vault-token-balance` to inspect tokens waiting for conversion inside the fee vault.

### Fee flow

The fee system now works in two stages:

- A configurable operations slice is paid out first to `OPERATIONS_FEE_CLAIMER`.
- All remaining fee tokens are sent directly from the router to `FeeVault`.
- Your executor cron then calls `FeeVault.executeAndDistribute(...)` to swap accumulated tokens into `USDC` and distribute the recovered `USDC` in the same transaction.
- The vault allocates recovered `USDC` in this order:
  1. recovery bucket until `RECOVERY_CAP_USDC`
  2. development bucket until `DEVELOPMENT_CAP_USDC`
  3. post-cap split between `POST_CAP_COMPANY_RECIPIENT` and `PROTOCOL_RECIPIENT`
- If a recipient is unset, that share stays pending in the vault until `vault-distribute-pending-usdc` is called after the recipient is configured.
- If `OPERATIONS_FEE_CLAIMER` is unset, the operations slice stays claimable from the router as a fallback.

The cap accounting uses actual recovered `USDC` base units. For example, `50,000 USDC` with 6 decimals is stored as `50000000000`.

Recommended setup order:

1. `upgrade -> router`
2. `deploy -> feevault` or `upgrade -> feevault`
3. `admin -> router-set-fee-vault`
4. `admin -> router-set-operations-fee-claimer`
5. `admin -> router-set-operations-fee-bps`
6. `admin -> vault-set-router`
7. `admin -> vault-set-executor`
8. `admin -> vault-set-recovery-recipient`
9. `admin -> vault-set-recovery-cap-usdc`
10. Optional: `admin -> vault-set-development-recipient`
11. Optional: `admin -> vault-set-development-cap-usdc`
12. `admin -> vault-set-postcap-company-recipient`
13. `admin -> vault-set-protocol-recipient`
14. `admin -> vault-set-postcap-company-bps`
15. `admin -> vault-set-allowed-target`
16. `admin -> vault-set-token-approval`

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
forge script script/admin/UpgradeFeeVault.s.sol --rpc-url sepolia --broadcast
forge script script/admin/ManageRouterFees.s.sol:ManageRouterFees --sig "runStatus()" --rpc-url sepolia
forge script script/admin/ManageFeeVault.s.sol:ManageFeeVault --sig "runStatus()" --rpc-url sepolia
forge script script/admin/UpdateAdapters.s.sol --account deployer --rpc-url sepolia --broadcast
forge script script/admin/UpdateHopTokens.s.sol --account deployer --rpc-url sepolia --broadcast
forge script script/admin/ManageUniswapV4Pools.s.sol --account deployer --rpc-url sepolia --broadcast
```
