// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Greeter
 * @notice A contract that simulates being imported from a package like @openzeppelin/foundry-upgrades
 * 
 * This contract is used to demonstrate the vm.getCode() issue when importing contracts
 * from external packages. The same issue occurs: artifacts from packages are not loaded
 * into EDR's available_artifacts collection.
 */
contract Greeter is Initializable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    string public greeting;

    function initialize(address initialOwner, string memory _greeting) public initializer {
        __Ownable_init(initialOwner);
        greeting = _greeting;
    }
}
