// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
// Import works fine - Hardhat resolves this at compile time from source files
import { SimpleContract } from "../../contracts/SimpleContract.sol";

/**
 * @title TestContract
 * @notice Demonstrates that vm.getCode() fails for contracts in contracts/
 * 
 * This test file compiles to: cache/test-artifacts/test/solidity/Test.t.sol/TestContract.json
 * The artifact has sourceName: "test/solidity/Test.t.sol"
 * 
 * This artifact IS loaded into EDR because it's in the "tests" scope.
 * But SimpleContract.sol's artifact is NOT loaded because it's in "contracts" scope.
 */
contract TestContract is Test {
    /**
     * @notice This test will FAIL with "no matching artifact found"
     * 
     * Why it fails:
     * 1. SimpleContract.sol compiles to artifacts/contracts/SimpleContract.sol/SimpleContract.json
     * 2. Hardhat 3 only loads artifacts from cache/test-artifacts/ (tests scope)
     * 3. Artifacts from artifacts/contracts/ (contracts scope) are never loaded into EDR
     * 4. vm.getCode() searches EDR's available_artifacts collection
     * 5. SimpleContract.sol is not in that collection, so it fails
     * 
     * Note: The import above works fine because Hardhat resolves imports from source files.
     * But vm.getCode() needs artifacts to be loaded into EDR's memory, which doesn't happen.
     */
    function testGetCode() public {
        // This will fail with "Error: no matching artifact found" when:
        // 1. Running `hardhat test solidity` without compiling first, OR
        // 2. When Hardhat doesn't load artifacts from contracts/ scope into EDR
        //
        // The issue: Hardhat's `test solidity` command only compiles test files,
        // not main contracts. Even if artifacts exist from a previous compilation,
        // they may not be loaded into EDR's available_artifacts collection.
        bytes memory code = vm.getCode("SimpleContract.sol");
        
        // If we get here, the test passes (but it will fail in the scenario above)
        assertTrue(code.length > 0);
    }
}

