#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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

select_component() {
  echo "Choose action:"
  select c in router upgrade-router uniswapv2 uniswapv3 pancakev3 kyber uniswapv4 wnative kuru v3staticquoter quit; do
    case "$c" in
      router)
        ACTION_LABEL='deploy router'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runRouter(string)'
        break
        ;;
      upgrade-router)
        ACTION_LABEL='upgrade router'
        SCRIPT_TARGET='script/admin/UpgradeRouter.s.sol:UpgradeRouter'
        SIG=''
        break
        ;;
      uniswapv2)
        ACTION_LABEL='deploy uniswapv2 adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runUniswapV2(string)'
        break
        ;;
      uniswapv3)
        ACTION_LABEL='deploy uniswapv3 adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runUniswapV3(string)'
        break
        ;;
      pancakev3)
        ACTION_LABEL='deploy pancakev3 adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runPancakeV3(string)'
        break
        ;;
      kyber)
        ACTION_LABEL='deploy kyber adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runKyberElastic(string)'
        break
        ;;
      uniswapv4)
        ACTION_LABEL='deploy uniswapv4 adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runUniswapV4(string)'
        break
        ;;
      wnative)
        ACTION_LABEL='deploy wnative adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runWNative(string)'
        break
        ;;
      kuru)
        ACTION_LABEL='deploy kuru adapter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runKuru(string)'
        break
        ;;
      v3staticquoter)
        ACTION_LABEL='deploy v3 static quoter'
        SCRIPT_TARGET='script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable'
        SIG='runUniswapV3StaticQuoter()'
        break
        ;;
      quit) exit 0 ;;
      *) echo "Invalid option" ;;
    esac
  done
}

confirm_broadcast() {
  read -r -p "Broadcast transaction? [y/N]: " yn
  case "$yn" in
    [Yy]*)
      BROADCAST='--broadcast'
      PK_VAR="${PREFIX}_PK_DEPLOYER"
      DEPLOYER_PK="${!PK_VAR:-}"
      if [[ -z "$DEPLOYER_PK" ]]; then
        echo "Missing $PK_VAR in your environment/.env"
        exit 1
      fi
      ;;
    *) BROADCAST='' ;;
  esac
}

main() {
  cd "$ROOT_DIR"
  load_env
  select_network
  select_component
  confirm_broadcast

  echo "Running $ACTION_LABEL for $PREFIX on rpc alias '$RPC_ALIAS'"
  CMD=(forge script "$SCRIPT_TARGET" --rpc-url "$RPC_ALIAS")

  if [[ -n "$SIG" ]]; then
    CMD+=(--sig "$SIG")
  fi

  if [[ "$SIG" == *"(string)"* ]]; then
    CMD+=("$PREFIX")
  fi

  if [[ -n "$BROADCAST" ]]; then
    CMD+=(--private-key "$DEPLOYER_PK" --broadcast)
  fi

  "${CMD[@]}"
}

main "$@"
