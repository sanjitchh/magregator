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
  select c in router-fee-status router-native-balance router-token-balance router-fee-usd-value router-set-fee-claimer router-set-company-fee-claimer router-set-operations-fee-claimer router-set-operations-fee-bps router-set-company-pre-cap-enabled router-set-company-post-cap-fee-bps router-set-company-fee-cap-usd router-set-price-feed router-set-price-feed-staleness router-claim-operations-fees router-claim-company-fees router-claim-protocol-fees update-adapters update-hop-tokens manage-uniswapv4-pools back; do
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
      router-set-fee-claimer)
        reset_action_config
        ACTION_LABEL='update router protocol fee claimer'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetFeeClaimer(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New protocol fee claimer address')")
        break
        ;;
      router-set-company-fee-claimer)
        reset_action_config
        ACTION_LABEL='update company fee claimer'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetCompanyFeeClaimer(address)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_address 'New company fee claimer address')")
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
      router-set-company-pre-cap-enabled)
        reset_action_config
        ACTION_LABEL='update company pre-cap mode'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetCompanyPreCapEnabled(bool)'
        MUTATES_STATE=1
        prompt_enabled_disabled 'Set company pre-cap mode to:'
        break
        ;;
      router-set-company-post-cap-fee-bps)
        reset_action_config
        ACTION_LABEL='update company post-cap fee bps'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetCompanyPostCapFeeBps(uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_uint 'Company post-cap fee bps')")
        break
        ;;
      router-set-company-fee-cap-usd)
        reset_action_config
        ACTION_LABEL='update company fee cap usd'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetCompanyFeeCapUsdWhole(uint256)'
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
      router-set-price-feed-staleness)
        reset_action_config
        ACTION_LABEL='update price feed staleness'
        SCRIPT_TARGET='script/admin/ManageRouterFees.s.sol:ManageRouterFees'
        SIG='runSetPriceFeedStaleness(uint256)'
        MUTATES_STATE=1
        EXTRA_ARGS=("$(prompt_uint 'Price feed staleness in seconds')")
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
