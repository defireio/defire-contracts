pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";

/**
 * @title IterableRegistry
 * @dev Manages an iterable set of elements.
 */
contract IterableRegistry is Initializable, Ownable {
    mapping(address => bool) contains;
    address[] elements;

    /**
     * Initialize the contract.
     * @param _owner account that is owner of the registry.
     */
    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);
    }

    /**
     * Returns the total amount of elements.
     */
    function getTotalElements() public view returns (uint256) {
        return elements.length;
    }

    /**
     * Returns an array of all the elements it contains.
     */
    function getElements() public view returns (address[] memory) {
        return elements;
    }

    /**
     * Returns the index of an element.
     * If not found, returns array length.
     * @param _element element to get index.
     */
    function getIndex(address _element) private view returns (uint256) {
        for (uint256 i = 0; i < elements.length; i++) {
            if (elements[i] == _element) {
                return i;
            }
        }
        return elements.length;
    }

    /**
     * Returns an element at a specific index.
     * @param _index index of the element.
     */
    function getElementAtIndex(uint256 _index) public view returns (address) {
        return elements[_index];
    }

    /**
     * Returns true if it contains the element.
     * @param _element element to check.
     */
    function isElement(address _element) public view returns (bool) {
        return contains[_element];
    }

    /**
     * Add new element if it does not contain it.
     * @param _element element to add.
     */
    function addElement(address _element) public onlyOwner returns (bool) {
        bool exists = contains[_element] != false;
        if (!exists) {
            elements.push(_element);
        }
        contains[_element] = true;
        return true;
    }

    /**
     * Remove element if it contains it.
     * @param _element element to remove.
     */
    function removeElement(address _element)
        public
        onlyOwner
        returns (address)
    {
        contains[_element] = false;
        uint256 index = getIndex(_element);
        //if element exists
        if (index != elements.length) {
            //If there more than one element move the last one to the index of the one to delete
            if (elements.length > 1) {
                elements[index] = elements[elements.length - 1];
            }
            elements.length--;
        }
    }
}
