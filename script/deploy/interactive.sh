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

prompt_hold_fees() {
  echo "Set hold fees to:"
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

prompt_special_redeem_enabled() {
  echo "Set special redeem to:"
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

prompt_whole_usd() {
  prompt_uint 'USD amount in whole dollars'
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
  select c in router uniswapv2 uniswapv3 pancakev3 kyber uniswapv4 wnative kuru v3staticquoter back; do
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
  select c in router back; do
    case "$c" in
      router)
        reset_action_config
        ACTION_LABEL='upgrade router'
        SCRIPT_TARGET='script/admin/UpgradeRouter.s.sol:UpgradeRouter'
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
  select c in router-fee-status router-native-balance router-token-balance router-fee-usd-value router-set-hold-fees router-set-fee-claimer router-set-deployer-redeemer router-set-special-enabled router-set-special-cap-usd router-set-price-feed router-claim-fees router-claim-special-fees update-adapters update-hop-tokens manage-uniswapv4-pools back; do
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
      router-fee-usd-value)
        reset_action_config
        ACTION_LABEL='show router fee usd value'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runFeeUsdValue(address,uint256)'
        EXTRA_ARGS=(
          "$(prompt_token_address)"
          "$(prompt_uint 'Token amount in base units')"
        )
        break
        ;;
      router-set-hold-fees)
        reset_action_config
        ACTION_LABEL='update router hold fees flag'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetHoldFees(bool)'
        MUTATES_STATE=1
        prompt_hold_fees
        break
        ;;
      router-set-fee-claimer)
        reset_action_config
        ACTION_LABEL='update router fee claimer'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetFeeClaimer(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New fee claimer address')")
        break
        ;;
      router-set-deployer-redeemer)
        reset_action_config
        ACTION_LABEL='update deployer redeemer'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetDeployerRedeemer(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New deployer redeemer address')")
        break
        ;;
      router-set-special-enabled)
        reset_action_config
        ACTION_LABEL='update special redeem mode'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetSpecialRedeemEnabled(bool)'
        MUTATES_STATE=1
        prompt_special_redeem_enabled
        break
        ;;
      router-set-special-cap-usd)
        reset_action_config
        ACTION_LABEL='update special redeem cap usd'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetSpecialRedeemCapUsdWhole(uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_whole_usd)")
        break
        ;;
      router-set-price-feed)
        reset_action_config
        ACTION_LABEL='update fee token price feed'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetFeePriceFeed(address,address)'
        MUTATES_STATE=1
        EXTRA_ARGS=(
          "$(prompt_token_address)"
          "$(prompt_address 'USD price feed address')"
        )
        break
        ;;
      router-claim-fees)
        reset_action_config
        ACTION_LABEL='claim router fees'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runClaimFees(address,address,uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=(
          "$(prompt_address 'Fee token address (use 0x0000000000000000000000000000000000000000 for native)')"
          "$(prompt_address 'Recipient address')"
          "$(prompt_uint 'Amount in token base units')"
        )
        break
        ;;
      router-claim-special-fees)
        reset_action_config
        ACTION_LABEL='claim special router fees'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runClaimSpecialFees(address,uint256)'
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
