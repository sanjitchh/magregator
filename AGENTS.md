              # AGENTS.md

## Repo overview

- This repo is a Foundry-based Solidity project for the Moksa aggregator.
- The core router is `src/MoksaRouter.sol` and it uses UUPS upgradeability.
- Deployment and admin workflows live under `script/deploy` and `script/admin`.

## Working rules for agents

- Prefer minimal, targeted changes that preserve the existing project style.
- Treat `src/MoksaRouter.sol` as upgradeable storage-sensitive code; only append new storage variables.
- When changing router/admin flows, also check whether `src/interface/IMoksaRouter.sol` and the interactive shell launcher need updates.
- Keep deployment and operational changes accessible from `script/deploy/interactive.sh` when practical.
- Prefer adding dedicated Foundry scripts in `script/admin` for repeatable on-chain admin actions instead of one-off command recipes.

## Validation

- For Solidity changes, run `forge build` at minimum.
- For shell changes, run `bash -n script/deploy/interactive.sh`.
- If both Solidity and shell are touched, run both validations.

## Operational context

- Supported networks are currently Ethereum mainnet, Monad, and Sepolia.
- The interactive menu expects `.env` values like `ETHEREUM_*`, `MONAD_*`, or `SEPOLIA_*`.
- Broadcasted interactive actions rely on `<PREFIX>_PK_DEPLOYER`.

## Documentation expectations

- Update `README.md` when changing deploy, upgrade, or admin flows.
- Keep examples concrete and use existing script paths.
