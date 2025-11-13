// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
// Import works fine - Hardhat resolves this at compile time from source files
import { SimpleContract } from "../../contracts/SimpleContract.sol";

// Import from external package - this also works at compile time
// Note: The actual @openzeppelin/foundry-upgrades package doesn't include Greeter,
// so we use a local Greeter contract that simulates the package import scenario.
// The same issue occurs: contracts from packages (or contracts/ directory) are not
// loaded into EDR's available_artifacts collection.
import { Greeter } from "../../contracts/Greeter.sol";
// Note: We don't import Upgrades/Options here because foundry-upgrades uses
// Foundry-specific cheatcodes that don't exist in Hardhat. The core issue
// (vm.getCode() failing for package contracts) is demonstrated by testGetCodeFromPackage().
// import { Upgrades } from "@openzeppelin/foundry-upgrades/src/Upgrades.sol";
// import { Options } from "@openzeppelin/foundry-upgrades/src/Options.sol";

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
    function testGetCode() public view {
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

    function testGetCodeAndCreate() public {
        // Real-world use case: Get bytecode and deploy contract
        // This is what foundry-upgrades and similar tools need to do
        // Example from Foundry docs: vm.getCode() then create
        
        bytes memory code = vm.getCode("SimpleContract.sol");
        assertTrue(code.length > 0, "Failed to get contract bytecode");
        
        // Encode constructor arguments and append to bytecode
        uint256 initialValue = 100;
        bytes memory constructorArgs = abi.encode(initialValue);
        bytes memory deploymentBytecode = abi.encodePacked(code, constructorArgs);
        
        // Deploy the contract using the bytecode with constructor arguments
        SimpleContract deployed;
        assembly {
            deployed := create(0, add(deploymentBytecode, 0x20), mload(deploymentBytecode))
        }
        
        require(address(deployed) != address(0), "Deployment failed");
        
        // Verify the contract works - check initial value from constructor
        assertEq(deployed.value(), initialValue);
        
        // Update and verify
        deployed.setValue(42);
        assertEq(deployed.value(), 42);
    }

    /**
     * @notice This test demonstrates the issue when importing contracts from external packages
     * 
     * When importing contracts from packages (e.g., openzeppelin/foundry-upgrades),
     * the same issue occurs: vm.getCode() cannot find the artifact because:
     * 
     * 1. Contracts from packages are compiled to artifacts in node_modules/...
     * 2. Hardhat 3 only loads artifacts from cache/test-artifacts/ (tests scope)
     * 3. Artifacts from packages are NOT loaded into EDR's available_artifacts collection
     * 4. vm.getCode() searches EDR's in-memory artifact collection, not the file system
     * 5. The contract from the package is not in that collection, so it fails
     * 
     * This is a real-world scenario that breaks tools like foundry-upgrades when they try to:
     * - Import contracts from packages
     * - Use vm.getCode() to get their bytecode for deployment
     * - Deploy proxies using upgrade libraries
     * 
     * Note: The import works fine because Hardhat resolves imports from source files.
     * But vm.getCode() needs artifacts to be loaded into EDR's memory, which doesn't happen.
     */
    function testGetCodeFromPackage() public view {
        // This will fail with "Error: no matching artifact found" because:
        // 1. Greeter is imported from a package (simulated with local contract)
        // 2. The package contract's artifact is not loaded into EDR
        // 3. vm.getCode() cannot find it in the available_artifacts collection
        
        // Try to get bytecode for Greeter
        // When importing from a package, the path format would be something like:
        // "package-name/path/to/contract.sol:ContractName"
        // But since we're using a local contract that simulates the package scenario,
        // we use the local path. The same issue occurs - the artifact is not loaded into EDR.
        bytes memory code = vm.getCode("Greeter.sol");
        
        // If we get here, the test passes (but it will fail in the scenario above)
        assertTrue(code.length > 0, "Failed to get contract bytecode from package");
    }

    /**
     * @notice This test demonstrates the issue when using upgrade libraries with package contracts
     * 
     * This is the exact scenario mentioned in the issue: when using upgrade libraries (like
     * foundry-upgrades) to deploy a proxy for a contract imported from a package,
     * vm.getCode() fails internally.
     * 
     * Upgrade libraries internally use vm.getCode() to get the implementation contract's
     * bytecode, which fails for package contracts.
     * 
     * NOTE: This test is commented out because foundry-upgrades uses Foundry-specific
     * cheatcodes (like vm.contains) that don't exist in Hardhat's Vm interface.
     * However, the core issue is the same: vm.getCode() cannot find artifacts from packages.
     * 
     * This test would FAIL because:
     * 1. Upgrade libraries internally call vm.getCode() to get the contract bytecode
     * 2. vm.getCode() cannot find Greeter's artifact because it's from a package
     * 3. The artifact is not loaded into EDR's available_artifacts collection
     * 
     * Even with unsafeSkipAllChecks = true, the deployment would fail at the vm.getCode() step
     * because the artifact lookup happens before any validation checks.
     */
    // function testProxyAdminCheck_skipAll() public {
    //     // This test demonstrates the scenario where upgrade libraries fail when
    //     // trying to deploy proxies for contracts imported from packages.
    //     // 
    //     // The core issue is that vm.getCode() cannot find the artifact, which
    //     // is demonstrated by the testGetCodeFromPackage() test above.
    //     
    //     // address testOwner = address(0x1234);
    //     // Options memory opts;
    //     // opts.unsafeSkipAllChecks = true;
    //     // 
    //     // Upgrades.deployTransparentProxy(
    //     //     "Greeter.sol",
    //     //     testOwner,
    //     //     abi.encodeCall(Greeter.initialize, (testOwner, "hello")),
    //     //     opts
    //     // );
    // }
}

