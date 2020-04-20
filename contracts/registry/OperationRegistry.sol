pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./IterableRegistry.sol";

/**
 * @title OperationRegistry
 * @dev Registry of valid operations.
 */
contract OperationRegistry is Initializable, Ownable, IterableRegistry {
    /**
     * Initialize the contract.
     * @param _owner account that is owner of the registry.
     */
    function initialize(address _owner) public initializer {
        IterableRegistry.initialize(_owner);
    }
}
