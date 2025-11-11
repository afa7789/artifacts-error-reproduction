// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleContract
 * @notice A minimal contract to demonstrate the vm.getCode() issue
 * 
 * This contract compiles to: artifacts/contracts/SimpleContract.sol/SimpleContract.json
 * The artifact has sourceName: "contracts/SimpleContract.sol"
 * 
 * PROBLEM: This artifact is NOT loaded into EDR's available_artifacts collection
 * because Hardhat 3 only loads artifacts from "tests" scope (cache/test-artifacts/),
 * not from "contracts" scope (artifacts/contracts/).
 */
contract SimpleContract {
    uint256 public value;

    constructor(uint256 _value) {
        value = _value;
    }

    function setValue(uint256 _value) public {
        value = _value;
    }
}

