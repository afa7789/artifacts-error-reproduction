# Minimal Reproduction
## vm.getCode() Can't Find Main Contracts in Hardhat 3

This repository demonstrates a bug in Hardhat 3 where `vm.getCode()` fails to find artifacts from contracts in the `contracts/` directory.

## Installation

```bash
npm install
```

## Running

```bash
npm run test:reproduce
```

Expected output: `Error: no matching artifact found`

## The Issue

When running `hardhat test solidity`, Hardhat only compiles test files (from `test/solidity/`), not main contracts (from `contracts/`). This causes `vm.getCode()` to fail with "no matching artifact found" because:

1. Main contract artifacts don't exist (they're never compiled)
2. Even if artifacts exist from a previous `hardhat compile`, Hardhat 3 only loads artifacts from the "tests" scope (`cache/test-artifacts/`) into EDR, not from the "contracts" scope (`artifacts/contracts/`)
3. `vm.getCode()` searches EDR's in-memory artifact collection, not the file system

**Real-world impact:** This breaks the common pattern of `vm.getCode()` followed by contract deployment (as shown in Foundry docs), which is needed by tools like foundry-upgrades.

**Root Cause:** Hardhat 3's `task-action.ts` only loads artifacts from the "tests" scope into EDR. There's no code to load artifacts from the "contracts" scope.

**Fix Needed:** `hardhat test solidity` should compile main contracts (or load existing artifacts into EDR) before running tests.

## PR

Nomic is working on it over this PR: https://github.com/NomicFoundation/hardhat/pull/7686
