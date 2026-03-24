#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

ACTION_LABEL=''
SCRIPT_TARGET=''
SIG=''
NEEDS_PREFIX=0
MUTATES_STATE=0
DEPLOYER_PK=''
declare -a EXTRA_ARGS=()

reset_action_config() {
  ACTION_LABEL=''
  SCRIPT_TARGET=''
  SIG=''
  NEEDS_PREFIX=0
  MUTATES_STATE=0
  DEPLOYER_PK=''
  EXTRA_ARGS=()
}

load_env() {
  if [[ -f "$ROOT_DIR/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$ROOT_DIR/.env"
    set +a
  fi
}

resolve_gas_estimate_multiplier() {
  local value=''
  local per_network_var="${PREFIX}_GAS_ESTIMATE_MULTIPLIER"

  value="${!per_network_var:-}"
  if [[ -n "$value" ]]; then
    printf '%s' "$value"
    return
  fi

  if [[ "$RPC_ALIAS" == 'monad' ]]; then
    printf '200'
  fi
}

select_network() {
  echo "Choose network:"
  select net in monad sepolia; do
    case "$net" in
      monad)
        PREFIX="MONAD"
        RPC_ALIAS="monad"
        break
        ;;
      sepolia)
        PREFIX="SEPOLIA"
        RPC_ALIAS="sepolia"
        break
        ;;
      *) echo "Invalid option" ;;
    esac
  done
}

prompt_address() {
  local prompt="$1"
  local value
  read -r -p "$prompt: " value
  printf '%s' "$value"
}

prompt_uint() {
  local prompt="$1"
  local value
  read -r -p "$prompt: " value
  printf '%s' "$value"
}

prompt_token_address() {
  prompt_address 'Token address'
}

prompt_whole_usd() {
  prompt_uint 'USD amount in whole dollars'
}

prompt_enabled_disabled() {
  local prompt="$1"
  echo "$prompt"
  select choice in enabled disabled; do
    case "$choice" in
      enabled)
        EXTRA_ARGS=(true)
        break
        ;;
      disabled)
        EXTRA_ARGS=(false)
        break
        ;;
      *) echo "Invalid option" ;;
    esac
  done
}

prompt_bool() {
  local prompt="$1"
  local value=''
  printf '%s\n' "$prompt" >&2
  select choice in enabled disabled; do
    case "$choice" in
      enabled)
        value=true
        break
        ;;
      disabled)
        value=false
        break
        ;;
      *) printf '%s\n' "Invalid option" >&2 ;;
    esac
  done
  printf '%s' "$value"
}

select_group() {
  echo "Choose action group:"
  select group in deploy upgrade admin inspect quit; do
    case "$group" in
      deploy)
        select_deploy_action
        break
        ;;
      upgrade)
        select_upgrade_action
        break
        ;;
      admin)
        select_admin_action
        break
        ;;
      inspect)
        select_inspect_action
        break
        ;;
      quit) exit 0 ;;
      *) echo "Invalid option" ;;
    esac
  done
}

select_deploy_action() {
  while true; do
    echo "Choose deploy action:"
    select c in router feevault adapters v3staticquoter back; do
      case "$c" in
        router)
          reset_action_config
          ACTION_LABEL='deploy router'
          SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
          SIG='runRouter(string)'
          NEEDS_PREFIX=1
          MUTATES_STATE=1
          return 0
          ;;
        feevault)
          reset_action_config
          ACTION_LABEL='deploy fee vault'
          SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
          SIG='runFeeVault(string)'
          NEEDS_PREFIX=1
          MUTATES_STATE=1
          return 0
          ;;
        adapters)
          if select_deploy_adapter_action; then
            return 0
          fi
          break
          ;;
        v3staticquoter)
          reset_action_config
          ACTION_LABEL='deploy v3 static quoter'
          SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
          SIG='runUniswapV3StaticQuoter()'
          MUTATES_STATE=1
          return 0
          ;;
        back)
          select_group
          return 0
          ;;
        *) echo "Invalid option" ;;
      esac
    done
  done
}

select_deploy_adapter_action() {
  echo "Choose adapter deploy action:"
  select c in uniswapv2 uniswapv3 pancakev3 kyber uniswapv4 wnative kuru back; do
    case "$c" in
      uniswapv2)
        reset_action_config
        ACTION_LABEL='deploy uniswapv2 adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runUniswapV2(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        return 0
        ;;
      uniswapv3)
        reset_action_config
        ACTION_LABEL='deploy uniswapv3 adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runUniswapV3(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        return 0
        ;;
      pancakev3)
        reset_action_config
        ACTION_LABEL='deploy pancakev3 adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runPancakeV3(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        return 0
        ;;
      kyber)
        reset_action_config
        ACTION_LABEL='deploy kyber adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runKyberElastic(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        return 0
        ;;
      uniswapv4)
        reset_action_config
        ACTION_LABEL='deploy uniswapv4 adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runUniswapV4(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        return 0
        ;;
      wnative)
        reset_action_config
        ACTION_LABEL='deploy wnative adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runWNative(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        return 0
        ;;
      kuru)
        reset_action_config
        ACTION_LABEL='deploy kuru adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runKuru(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        return 0
        ;;
      back)
        return 1
        ;;
      *) echo "Invalid option" ;;
    esac
  done
}

select_upgrade_action() {
  while true; do
    echo "Choose upgrade action:"
    select c in router feevault adapters back; do
      case "$c" in
        router)
          reset_action_config
          ACTION_LABEL='upgrade router'
          SCRIPT_TARGET='script/admin/UpgradeRouter.s.sol:UpgradeRouter'
          MUTATES_STATE=1
          return 0
          ;;
        feevault)
          reset_action_config
          ACTION_LABEL='upgrade fee vault'
          SCRIPT_TARGET='script/admin/UpgradeFeeVault.s.sol:UpgradeFeeVault'
          MUTATES_STATE=1
          return 0
          ;;
        adapters)
          if select_upgrade_adapter_action; then
            return 0
          fi
          break
          ;;
        back)
          select_group
          return 0
          ;;
        *) echo "Invalid option" ;;
      esac
    done
  done
}

select_upgrade_adapter_action() {
  echo "Choose adapter upgrade action:"
  select c in uniswapv2 uniswapv3 pancakev3 kyber uniswapv4 wnative kuru back; do
    case "$c" in
      uniswapv2)
        reset_action_config
        ACTION_LABEL='upgrade uniswapv2 adapter'
        SCRIPT_TARGET='script/admin/UpgradeAdapters.s.sol:UpgradeAdapters'
        SIG='runUniswapV2()'
        MUTATES_STATE=1
        return 0
        ;;
      uniswapv3)
        reset_action_config
        ACTION_LABEL='upgrade uniswapv3 adapter'
        SCRIPT_TARGET='script/admin/UpgradeAdapters.s.sol:UpgradeAdapters'
        SIG='runUniswapV3()'
        MUTATES_STATE=1
        return 0
        ;;
      pancakev3)
        reset_action_config
        ACTION_LABEL='upgrade pancakev3 adapter'
        SCRIPT_TARGET='script/admin/UpgradeAdapters.s.sol:UpgradeAdapters'
        SIG='runPancakeV3()'
        MUTATES_STATE=1
        return 0
        ;;
      kyber)
        reset_action_config
        ACTION_LABEL='upgrade kyber adapter'
        SCRIPT_TARGET='script/admin/UpgradeAdapters.s.sol:UpgradeAdapters'
        SIG='runKyberElastic()'
        MUTATES_STATE=1
        return 0
        ;;
      uniswapv4)
        reset_action_config
        ACTION_LABEL='upgrade uniswapv4 adapter'
        SCRIPT_TARGET='script/admin/UpgradeAdapters.s.sol:UpgradeAdapters'
        SIG='runUniswapV4()'
        MUTATES_STATE=1
        return 0
        ;;
      wnative)
        reset_action_config
        ACTION_LABEL='upgrade wnative adapter'
        SCRIPT_TARGET='script/admin/UpgradeAdapters.s.sol:UpgradeAdapters'
        SIG='runWNative()'
        MUTATES_STATE=1
        return 0
        ;;
      kuru)
        reset_action_config
        ACTION_LABEL='upgrade kuru adapter'
        SCRIPT_TARGET='script/admin/UpgradeAdapters.s.sol:UpgradeAdapters'
        SIG='runKuru()'
        MUTATES_STATE=1
        return 0
        ;;
      back)
        return 1
        ;;
      *) echo "Invalid option" ;;
    esac
  done
}

select_admin_router_action() {
  echo "Choose router admin action:"
  select c in fee-status native-balance token-balance set-fee-vault set-fee-claimer set-company-fee-claimer set-operations-fee-claimer set-operations-fee-bps claim-operations-fees back; do
    case "$c" in
      fee-status)
        reset_action_config
        ACTION_LABEL='show router fee settings'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runStatus()'
        return 0
        ;;
      native-balance)
        reset_action_config
        ACTION_LABEL='show router native balance'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runNativeBalance()'
        return 0
        ;;
      token-balance)
        reset_action_config
        ACTION_LABEL='show router token balance'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runTokenBalance(address)'
        EXTRA_ARGS=("$(prompt_token_address)")
        return 0
        ;;
      set-fee-vault)
        reset_action_config
        ACTION_LABEL='update router fee vault'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetFeeVault(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New fee vault address')")
        return 0
        ;;
      set-fee-claimer)
        reset_action_config
        ACTION_LABEL='update legacy router protocol fee claimer'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetFeeClaimer(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New legacy protocol fee claimer address')")
        return 0
        ;;
      set-company-fee-claimer)
        reset_action_config
        ACTION_LABEL='update legacy company fee claimer'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetCompanyFeeClaimer(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New legacy company fee claimer address')")
        return 0
        ;;
      set-operations-fee-claimer)
        reset_action_config
        ACTION_LABEL='update operations fee claimer'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetOperationsFeeClaimer(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New operations fee claimer address')")
        return 0
        ;;
      set-operations-fee-bps)
        reset_action_config
        ACTION_LABEL='update operations fee bps'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetOperationsFeeBps(uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_uint 'Operations fee bps')")
        return 0
        ;;
      claim-operations-fees)
        reset_action_config
        ACTION_LABEL='claim router operations fees'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runClaimOperationsFees(address,uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=(
          "$(prompt_address 'Fee token address (use 0x0000000000000000000000000000000000000000 for native)')"
          "$(prompt_uint 'Amount in token base units')"
        )
        return 0
        ;;
      back)
        return 1
        ;;
      *) echo "Invalid option" ;;
    esac
  done
}

select_admin_vault_action() {
  echo "Choose fee vault admin action:"
  select c in status token-balance set-router set-executor set-usdc migrate-usdc-accounting set-recovery-recipient set-recovery-cap-usdc set-development-recipient set-development-cap-usdc set-postcap-company-recipient set-protocol-recipient set-postcap-company-bps set-allowed-target set-token-approval allocate-and-distribute-usdc distribute-pending-usdc back; do
    case "$c" in
      status)
        reset_action_config
        ACTION_LABEL='show fee vault settings'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runStatus()'
        return 0
        ;;
      token-balance)
        reset_action_config
        ACTION_LABEL='show fee vault token balance'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runTokenBalance(address)'
        EXTRA_ARGS=("$(prompt_token_address)")
        return 0
        ;;
      set-router)
        reset_action_config
        ACTION_LABEL='update fee vault router'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetRouter(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New router address')")
        return 0
        ;;
      set-executor)
        reset_action_config
        ACTION_LABEL='update fee vault executor'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetExecutor(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New executor address')")
        return 0
        ;;
      set-usdc)
        reset_action_config
        ACTION_LABEL='update fee vault USDC'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetUsdc(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New USDC address')")
        return 0
        ;;
      migrate-usdc-accounting)
        reset_action_config
        ACTION_LABEL='migrate fee vault USDC accounting'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runMigrateUsdcAccounting(address,uint256,uint256,uint256,uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=(
          "$(prompt_address 'New USDC address')"
          "$(prompt_uint 'New recovery cap in USDC base units')"
          "$(prompt_uint 'New recovery accrued in USDC base units')"
          "$(prompt_uint 'New development cap in USDC base units')"
          "$(prompt_uint 'New development accrued in USDC base units')"
        )
        return 0
        ;;
      set-recovery-recipient)
        reset_action_config
        ACTION_LABEL='update recovery recipient'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetRecoveryRecipient(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New recovery recipient address')")
        return 0
        ;;
      set-recovery-cap-usdc)
        reset_action_config
        ACTION_LABEL='update recovery cap usdc'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetRecoveryCapUsdc(uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_uint 'Recovery cap in USDC base units')")
        return 0
        ;;
      set-development-recipient)
        reset_action_config
        ACTION_LABEL='update development recipient'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetDevelopmentRecipient(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New development recipient address')")
        return 0
        ;;
      set-development-cap-usdc)
        reset_action_config
        ACTION_LABEL='update development cap usdc'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetDevelopmentCapUsdc(uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_uint 'Development cap in USDC base units')")
        return 0
        ;;
      set-postcap-company-recipient)
        reset_action_config
        ACTION_LABEL='update post-cap company recipient'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetPostCapCompanyRecipient(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New post-cap company recipient address')")
        return 0
        ;;
      set-protocol-recipient)
        reset_action_config
        ACTION_LABEL='update protocol recipient'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetProtocolRecipient(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New protocol recipient address')")
        return 0
        ;;
      set-postcap-company-bps)
        reset_action_config
        ACTION_LABEL='update post-cap company bps'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetPostCapCompanyBps(uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_uint 'Post-cap company bps')")
        return 0
        ;;
      set-allowed-target)
        reset_action_config
        ACTION_LABEL='update allowed swap target'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetAllowedSwapTarget(address,bool)'
        MUTATES_STATE=1
        EXTRA_ARGS=(
          "$(prompt_address 'Swap target address')"
          "$(prompt_bool 'Set allowed swap target to:')"
        )
        return 0
        ;;
      set-token-approval)
        reset_action_config
        ACTION_LABEL='update fee vault token approval'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetTokenApproval(address,address,uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=(
          "$(prompt_token_address)"
          "$(prompt_address 'Approved spender address')"
          "$(prompt_uint 'Approval amount in token base units')"
        )
        return 0
        ;;
      allocate-and-distribute-usdc)
        reset_action_config
        ACTION_LABEL='allocate and distribute existing fee vault usdc'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runAllocateAndDistributeUsdc()'
        MUTATES_STATE=1
        return 0
        ;;
      distribute-pending-usdc)
        reset_action_config
        ACTION_LABEL='distribute pending fee vault usdc'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runDistributePendingUsdc()'
        MUTATES_STATE=1
        return 0
        ;;
      back)
        return 1
        ;;
      *) echo "Invalid option" ;;
    esac
  done
}

select_admin_sync_action() {
  echo "Choose sync/admin maintenance action:"
  select c in update-adapters update-hop-tokens manage-uniswapv4-pools back; do
    case "$c" in
      update-adapters)
        reset_action_config
        ACTION_LABEL='sync router adapters'
        SCRIPT_TARGET='script/admin/UpdateAdapters.s.sol:UpdateAdapters'
        MUTATES_STATE=1
        return 0
        ;;
      update-hop-tokens)
        reset_action_config
        ACTION_LABEL='sync router hop tokens'
        SCRIPT_TARGET='script/admin/UpdateHopTokens.s.sol:UpdateHopTokens'
        MUTATES_STATE=1
        return 0
        ;;
      manage-uniswapv4-pools)
        reset_action_config
        ACTION_LABEL='sync uniswapv4 pools'
        SCRIPT_TARGET='script/admin/ManageUniswapV4Pools.s.sol:ManageUniswapV4Pools'
        MUTATES_STATE=1
        return 0
        ;;
      back)
        return 1
        ;;
      *) echo "Invalid option" ;;
    esac
  done
}

select_admin_action() {
  while true; do
    echo "Choose admin category:"
    select c in router-fees fee-vault sync-tools back; do
      case "$c" in
        router-fees)
          if select_admin_router_action; then
            return
          fi
          break
          ;;
        fee-vault)
          if select_admin_vault_action; then
            return
          fi
          break
          ;;
        sync-tools)
          if select_admin_sync_action; then
            return
          fi
          break
          ;;
        back)
          select_group
          return
          ;;
        *) echo "Invalid option" ;;
      esac
    done
  done
}

select_inspect_action() {
  echo "Choose inspect action:"
  select c in list-adapters back; do
    case "$c" in
      list-adapters)
        reset_action_config
        ACTION_LABEL='list router adapters'
        SCRIPT_TARGET='script/admin/ListAdapters.s.sol:ListAdapters'
        break
        ;;
      back)
        select_group
        break
        ;;
      *) echo "Invalid option" ;;
    esac
  done
}

confirm_broadcast() {
  if [[ "$MUTATES_STATE" -eq 0 ]]; then
    return
  fi

  read -r -p "Broadcast transaction? [y/N]: " yn
  case "$yn" in
    [Yy]*)
      PK_VAR="${PREFIX}_PK_DEPLOYER"
      DEPLOYER_PK="${!PK_VAR:-}"
      if [[ -z "$DEPLOYER_PK" ]]; then
        echo "Missing $PK_VAR in your environment/.env"
        exit 1
      fi
      ;;
    *) DEPLOYER_PK='' ;;
  esac
}

main() {
  cd "$ROOT_DIR"
  load_env

  while true; do
    reset_action_config
    select_network
    select_group
    confirm_broadcast

    echo "Running $ACTION_LABEL for $PREFIX on rpc alias '$RPC_ALIAS'"
    CMD=(forge script "$SCRIPT_TARGET" --rpc-url "$RPC_ALIAS")

    if [[ -n "$SIG" ]]; then
      CMD+=(--sig "$SIG")
    fi

    if [[ "$NEEDS_PREFIX" -eq 1 ]]; then
      CMD+=("$PREFIX")
    fi

    if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
      CMD+=("${EXTRA_ARGS[@]}")
    fi

    if [[ -n "$DEPLOYER_PK" ]]; then
      CMD+=(--private-key "$DEPLOYER_PK" --broadcast)

      GAS_ESTIMATE_MULTIPLIER="$(resolve_gas_estimate_multiplier)"
      if [[ -n "$GAS_ESTIMATE_MULTIPLIER" ]]; then
        CMD+=(--gas-estimate-multiplier "$GAS_ESTIMATE_MULTIPLIER")
        echo "Using gas estimate multiplier: $GAS_ESTIMATE_MULTIPLIER"
      fi
    fi

    "${CMD[@]}"
    echo
  done
}

main "$@"
