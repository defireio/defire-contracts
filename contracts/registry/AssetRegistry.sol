pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./IterableRegistry.sol";

/**
 * @title AssetRegistry
 * @dev Registry of valid assets (ERC20 tokens).
 */
contract AssetRegistry is Initializable, IterableRegistry {
    /**
     * Initialize the contract.
     * @param _owner account that is owner of the registry.
     */
    function initialize(address _owner) public initializer {
        IterableRegistry.initialize(_owner);
    }
}
