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
  echo "Choose component to deploy (upgradeable proxy + implementation):"
  select c in router uniswapv2 uniswapv3 pancakev3 kyber uniswapv4 wnative kuru v3staticquoter quit; do
    case "$c" in
      router) SIG='runRouter(string)' ; break ;;
      uniswapv2) SIG='runUniswapV2(string)' ; break ;;
      uniswapv3) SIG='runUniswapV3(string)' ; break ;;
      pancakev3) SIG='runPancakeV3(string)' ; break ;;
      kyber) SIG='runKyberElastic(string)' ; break ;;
      uniswapv4) SIG='runUniswapV4(string)' ; break ;;
      wnative) SIG='runWNative(string)' ; break ;;
      kuru) SIG='runKuru(string)' ; break ;;
      v3staticquoter) SIG='runUniswapV3StaticQuoter()' ; break ;;
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

  echo "Running deploy for $PREFIX on rpc alias '$RPC_ALIAS' using $SIG"
  CMD=(forge script script/deploy/DeployUpgradeable.s.sol:DeployUpgradeable
    --sig "$SIG"
    --rpc-url "$RPC_ALIAS")

  if [[ "$SIG" == *"(string)"* ]]; then
    CMD+=("$PREFIX")
  fi

  if [[ -n "$BROADCAST" ]]; then
    CMD+=(--private-key "$DEPLOYER_PK" --broadcast)
  fi

  "${CMD[@]}"
}

main "$@"
