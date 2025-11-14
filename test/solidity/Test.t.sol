// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { Vm } from "forge-std/Vm.sol";
import { SimpleContract } from "../../contracts/SimpleContract.sol";
import { Greeter } from "../../contracts/Greeter.sol";
import { Upgrades } from "@openzeppelin/foundry-upgrades/src/Upgrades.sol";
import { Options } from "@openzeppelin/foundry-upgrades/src/Options.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @title TestContract
 * @notice Tests demonstrando o problema do vm.getCode() com contratos de pacotes externos
 */
contract TestContract is Test {
    address constant CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    // ========================================================================
    // [PASS] BASELINE: Testes que DEVEM passar (contratos locais)
    // ========================================================================

    function test_LOCAL_vmGetCode_SimpleContract_SHOULD_PASS() public view {
        bytes memory code = vm.getCode("SimpleContract.sol");
        assertTrue(code.length > 0, "Local contract should be found");
    }

    function test_LOCAL_vmGetCode_Greeter_SHOULD_PASS() public view {
        bytes memory code = vm.getCode("Greeter.sol");
        assertTrue(code.length > 0, "Local contract should be found");
    }

    function test_LOCAL_deployWithVmGetCode_SHOULD_PASS() public {
        bytes memory code = vm.getCode("SimpleContract.sol");
        uint256 initialValue = 100;
        bytes memory deploymentBytecode = abi.encodePacked(code, abi.encode(initialValue));
        
        SimpleContract deployed;
        assembly {
            deployed := create(0, add(deploymentBytecode, 0x20), mload(deploymentBytecode))
        }
        
        assertEq(deployed.value(), initialValue, "Deployed contract should work");
    }

    // ========================================================================
    // [FAIL] BUG EVIDENCE: Testes que DEVEM falhar (mostra o problema)
    // ========================================================================

    function test_PACKAGE_vmGetCode_TransparentProxy_EXPECT_FAIL() public view {
        // Este teste DEVE falhar - mostra o bug do Hardhat
        string memory contractName = "TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy";
        
        console.log("=== BUG DEMONSTRATION ===");
        console.log("Trying to get code for:", contractName);
        console.log("Note: This contract is imported and compiled, but vm.getCode() will fail");
        
        bytes memory code = vm.getCode(contractName);
        assertTrue(code.length > 0, "EXPECTED TO FAIL: Package contract artifacts not loaded in EDR");
    }

    function test_PACKAGE_vmGetCode_viaCheatcodeAddress_EXPECT_FAIL() public view {
        // Testa usando o mesmo método que foundry-upgrades usa
        string memory contractName = "TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy";
        
        console.log("=== Testing foundry-upgrades pattern ===");
        console.log("Using Vm(CHEATCODE_ADDRESS).getCode()");
        
        Vm vmInstance = Vm(CHEATCODE_ADDRESS);
        bytes memory code = vmInstance.getCode(contractName);
        assertTrue(code.length > 0, "EXPECTED TO FAIL: Package contract not found via cheatcode address");
    }

    function test_PACKAGE_deployTransparentProxy_EXPECT_FAIL() public {
        // Este é o caso de uso real que quebra
        console.log("=== Real-world use case that fails ===");
        console.log("Attempting to deploy TransparentUpgradeableProxy for Greeter");
        
        address testOwner = address(0x1234);
        Options memory opts;
        opts.unsafeSkipAllChecks = true;
        
        // Isto vai falhar porque TransparentUpgradeableProxy não está disponível
        Upgrades.deployTransparentProxy(
            "Greeter.sol",
            testOwner,
            abi.encodeCall(Greeter.initialize, (testOwner, "hello")),
            opts
        );
    }

    // ========================================================================
    // [INFO] DIAGNOSTIC: Testes para mostrar exatamente o que está acontecendo
    // ========================================================================

    function test_DIAGNOSTIC_showArtifactAvailability() public view {
        console.log("\n=== DIAGNOSTIC: Artifact Availability ===\n");
        
        string[6] memory contracts = [
            "SimpleContract.sol",
            "Greeter.sol", 
            "TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy",
            "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy",
            "contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy",
            "node_modules/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy"
        ];
        
        for (uint i = 0; i < contracts.length; i++) {
            console.log("Trying:", contracts[i]);
            try vm.getCode(contracts[i]) returns (bytes memory code) {
                console.log("  [FOUND] Length:", code.length);
            } catch {
                console.log("  [NOT FOUND]");
            }
            console.log("");
        }
    }

    function test_DIAGNOSTIC_compareMethods() public view {
        console.log("\n=== DIAGNOSTIC: Comparing vm.getCode() methods ===\n");
        
        string memory packageContract = "TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy";
        string memory localContract = "Greeter.sol";
        
        // Test package contract
        console.log("Package contract:", packageContract);
        console.log("  Method 1 (vm.getCode()):");
        try vm.getCode(packageContract) returns (bytes memory) {
            console.log("    [SUCCESS]");
        } catch {
            console.log("    [FAILED]");
        }
        
        console.log("  Method 2 (Vm(CHEATCODE_ADDRESS).getCode()):");
        try Vm(CHEATCODE_ADDRESS).getCode(packageContract) returns (bytes memory) {
            console.log("    [SUCCESS]");
        } catch {
            console.log("    [FAILED]");
        }
        
        console.log("");
        
        // Test local contract  
        console.log("Local contract:", localContract);
        console.log("  Method 1 (vm.getCode()):");
        try vm.getCode(localContract) returns (bytes memory) {
            console.log("    [SUCCESS]");
        } catch {
            console.log("    [FAILED]");
        }
        
        console.log("  Method 2 (Vm(CHEATCODE_ADDRESS).getCode()):");
        try Vm(CHEATCODE_ADDRESS).getCode(localContract) returns (bytes memory) {
            console.log("    [SUCCESS]");
        } catch {
            console.log("    [FAILED]");
        }
    }

    // ========================================================================
    // [PASS] WORKAROUND: Teste esperando erro (passa porque erro é esperado)
    // ========================================================================

    function test_WORKAROUND_expectRevert_onPackageContract_SHOULD_PASS() public {
        // Este teste PASSA porque esperamos o erro
        console.log("=== Testing that package contracts fail (as expected) ===");
        
        vm.expectRevert();
        this.tryGetCodeForPackageContract();
    }

    function tryGetCodeForPackageContract() external view {
        vm.getCode("TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy");
    }
}