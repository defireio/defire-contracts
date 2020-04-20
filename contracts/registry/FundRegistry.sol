pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";

interface Fund {
    function getFundToken() external view returns (address);
}


/**
 * @title FundRegistry
 * @dev Registry of valid funds.
 */
contract FundRegistry is Initializable, Ownable {
    mapping(address => bool) funds;
    mapping(address => bool) fundTokens;

    /**
     * Initialize the contract.
     * @param _owner account that is owner of the registry.
     */
    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);
    }

    /**
     * Returns true if the element is in the registry.
     * @param _fund element to check.
     */
    function isFund(address _fund) public view returns (bool) {
        return funds[_fund];
    }

    /**
     * Returns true if the element is in the registry.
     * @param _fundToken element to check.
     */
    function isFundToken(address _fundToken) public view returns (bool) {
        return fundTokens[_fundToken];
    }

    /**
     * Adds an element to the registry.
     * @param _fund element to add.
     */
    function addElement(address _fund) public onlyOwner returns (bool) {
        funds[_fund] = true;
        fundTokens[Fund(_fund).getFundToken()] = true;
        return true;
    }

    /**
     * Remove an element from the registry.
     * @param _fund element to remove.
     */
    function removeElement(address _fund) public onlyOwner returns (address) {
        funds[_fund] = false;
    }
}
