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
  echo "$prompt"
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
      *) echo "Invalid option" ;;
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
  echo "Choose deploy action:"
  select c in router feevault uniswapv2 uniswapv3 pancakev3 kyber uniswapv4 wnative kuru v3staticquoter back; do
    case "$c" in
      router)
        reset_action_config
        ACTION_LABEL='deploy router'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runRouter(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        break
        ;;
      feevault)
        reset_action_config
        ACTION_LABEL='deploy fee vault'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runFeeVault(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        break
        ;;
      uniswapv2)
        reset_action_config
        ACTION_LABEL='deploy uniswapv2 adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runUniswapV2(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        break
        ;;
      uniswapv3)
        reset_action_config
        ACTION_LABEL='deploy uniswapv3 adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runUniswapV3(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        break
        ;;
      pancakev3)
        reset_action_config
        ACTION_LABEL='deploy pancakev3 adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runPancakeV3(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        break
        ;;
      kyber)
        reset_action_config
        ACTION_LABEL='deploy kyber adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runKyberElastic(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        break
        ;;
      uniswapv4)
        reset_action_config
        ACTION_LABEL='deploy uniswapv4 adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runUniswapV4(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        break
        ;;
      wnative)
        reset_action_config
        ACTION_LABEL='deploy wnative adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runWNative(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        break
        ;;
      kuru)
        reset_action_config
        ACTION_LABEL='deploy kuru adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runKuru(string)'
        NEEDS_PREFIX=1
        MUTATES_STATE=1
        break
        ;;
      v3staticquoter)
        reset_action_config
        ACTION_LABEL='deploy v3 static quoter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runUniswapV3StaticQuoter()'
        MUTATES_STATE=1
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

select_upgrade_action() {
  echo "Choose upgrade action:"
  select c in router feevault back; do
    case "$c" in
      router)
        reset_action_config
        ACTION_LABEL='upgrade router'
        SCRIPT_TARGET='script/admin/UpgradeRouter.s.sol:UpgradeRouter'
        MUTATES_STATE=1
        break
        ;;
      feevault)
        reset_action_config
        ACTION_LABEL='upgrade fee vault'
        SCRIPT_TARGET='script/admin/UpgradeFeeVault.s.sol:UpgradeFeeVault'
        MUTATES_STATE=1
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

select_admin_action() {
  echo "Choose admin action:"
  select c in router-fee-status router-native-balance router-token-balance router-set-fee-vault router-set-fee-claimer router-set-company-fee-claimer router-set-operations-fee-claimer router-set-operations-fee-bps router-claim-operations-fees router-claim-company-fees router-claim-protocol-fees vault-status vault-token-balance vault-set-router vault-set-executor vault-set-usdc vault-set-recovery-recipient vault-set-recovery-cap-usdc vault-set-development-recipient vault-set-development-cap-usdc vault-set-postcap-company-recipient vault-set-protocol-recipient vault-set-postcap-company-bps vault-set-allowed-target vault-set-token-approval vault-distribute-pending-usdc update-adapters update-hop-tokens manage-uniswapv4-pools back; do
    case "$c" in
      router-fee-status)
        reset_action_config
        ACTION_LABEL='show router fee settings'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runStatus()'
        break
        ;;
      router-native-balance)
        reset_action_config
        ACTION_LABEL='show router native balance'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runNativeBalance()'
        break
        ;;
      router-token-balance)
        reset_action_config
        ACTION_LABEL='show router token balance'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runTokenBalance(address)'
        EXTRA_ARGS=("$(prompt_token_address)")
        break
        ;;
      router-set-fee-vault)
        reset_action_config
        ACTION_LABEL='update router fee vault'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetFeeVault(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New fee vault address')")
        break
        ;;
      router-set-fee-claimer)
        reset_action_config
        ACTION_LABEL='update legacy router protocol fee claimer'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetFeeClaimer(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New legacy protocol fee claimer address')")
        break
        ;;
      router-set-company-fee-claimer)
        reset_action_config
        ACTION_LABEL='update legacy company fee claimer'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetCompanyFeeClaimer(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New legacy company fee claimer address')")
        break
        ;;
      router-set-operations-fee-claimer)
        reset_action_config
        ACTION_LABEL='update operations fee claimer'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetOperationsFeeClaimer(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New operations fee claimer address')")
        break
        ;;
      router-set-operations-fee-bps)
        reset_action_config
        ACTION_LABEL='update operations fee bps'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetOperationsFeeBps(uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_uint 'Operations fee bps')")
        break
        ;;
      router-claim-operations-fees)
        reset_action_config
        ACTION_LABEL='claim router operations fees'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runClaimOperationsFees(address,uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=(
          "$(prompt_address 'Fee token address (use 0x0000000000000000000000000000000000000000 for native)')"
          "$(prompt_uint 'Amount in token base units')"
        )
        break
        ;;
      vault-status)
        reset_action_config
        ACTION_LABEL='show fee vault settings'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runStatus()'
        break
        ;;
      vault-token-balance)
        reset_action_config
        ACTION_LABEL='show fee vault token balance'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runTokenBalance(address)'
        EXTRA_ARGS=("$(prompt_token_address)")
        break
        ;;
      vault-set-router)
        reset_action_config
        ACTION_LABEL='update fee vault router'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetRouter(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New router address')")
        break
        ;;
      vault-set-executor)
        reset_action_config
        ACTION_LABEL='update fee vault executor'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetExecutor(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New executor address')")
        break
        ;;
      vault-set-usdc)
        reset_action_config
        ACTION_LABEL='update fee vault USDC'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetUsdc(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New USDC address')")
        break
        ;;
      vault-set-recovery-recipient)
        reset_action_config
        ACTION_LABEL='update recovery recipient'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetRecoveryRecipient(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New recovery recipient address')")
        break
        ;;
      vault-set-recovery-cap-usdc)
        reset_action_config
        ACTION_LABEL='update recovery cap usdc'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetRecoveryCapUsdc(uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_uint 'Recovery cap in USDC base units')")
        break
        ;;
      vault-set-development-recipient)
        reset_action_config
        ACTION_LABEL='update development recipient'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetDevelopmentRecipient(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New development recipient address')")
        break
        ;;
      vault-set-development-cap-usdc)
        reset_action_config
        ACTION_LABEL='update development cap usdc'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetDevelopmentCapUsdc(uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_uint 'Development cap in USDC base units')")
        break
        ;;
      vault-set-postcap-company-recipient)
        reset_action_config
        ACTION_LABEL='update post-cap company recipient'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetPostCapCompanyRecipient(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New post-cap company recipient address')")
        break
        ;;
      vault-set-protocol-recipient)
        reset_action_config
        ACTION_LABEL='update protocol recipient'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetProtocolRecipient(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New protocol recipient address')")
        break
        ;;
      vault-set-postcap-company-bps)
        reset_action_config
        ACTION_LABEL='update post-cap company bps'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetPostCapCompanyBps(uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_uint 'Post-cap company bps')")
        break
        ;;
      vault-set-allowed-target)
        reset_action_config
        ACTION_LABEL='update allowed swap target'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runSetAllowedSwapTarget(address,bool)'
        MUTATES_STATE=1
        EXTRA_ARGS=(
          "$(prompt_address 'Swap target address')"
          "$(prompt_bool 'Set allowed swap target to:')"
        )
        break
        ;;
      vault-set-token-approval)
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
        break
        ;;
      vault-distribute-pending-usdc)
        reset_action_config
        ACTION_LABEL='distribute pending fee vault usdc'
        SCRIPT_TARGET='script/admin/ManageFeeVault.s.sol:ManageFeeVault'
        SIG='runDistributePendingUsdc()'
        MUTATES_STATE=1
        break
        ;;
      router-claim-company-fees)
        reset_action_config
        ACTION_LABEL='claim router company fees'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runClaimCompanyFees(address,uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=(
          "$(prompt_token_address)"
          "$(prompt_uint 'Amount in token base units')"
        )
        break
        ;;
      router-claim-protocol-fees)
        reset_action_config
        ACTION_LABEL='claim router protocol fees'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runClaimProtocolFees(address,uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=(
          "$(prompt_token_address)"
          "$(prompt_uint 'Amount in token base units')"
        )
        break
        ;;
      update-adapters)
        reset_action_config
        ACTION_LABEL='sync router adapters'
        SCRIPT_TARGET='script/admin/UpdateAdapters.s.sol:UpdateAdapters'
        MUTATES_STATE=1
        break
        ;;
      update-hop-tokens)
        reset_action_config
        ACTION_LABEL='sync router hop tokens'
        SCRIPT_TARGET='script/admin/UpdateHopTokens.s.sol:UpdateHopTokens'
        MUTATES_STATE=1
        break
        ;;
      manage-uniswapv4-pools)
        reset_action_config
        ACTION_LABEL='sync uniswapv4 pools'
        SCRIPT_TARGET='script/admin/ManageUniswapV4Pools.s.sol:ManageUniswapV4Pools'
        MUTATES_STATE=1
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
    fi

    "${CMD[@]}"
    echo
  done
}

main "$@"
