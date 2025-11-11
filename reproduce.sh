#!/usr/bin/env bash

set -euo pipefail

# Clean artifacts and run test without compiling main contracts
# This demonstrates that 'hardhat test solidity' only compiles test files,
# causing vm.getCode() to fail with "no matching artifact found"

rm -rf artifacts cache
npx hardhat test solidity test/solidity/Test.t.sol

