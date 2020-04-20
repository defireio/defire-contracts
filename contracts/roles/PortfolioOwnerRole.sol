pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol";


/**
 * @title PortfolioOwnerRole
 * @dev PortfolioOwner are owners of the portfolio.
 * Assets can only be withdrawn to their addresses.
 */
contract PortfolioOwnerRole is Initializable {
    using Roles for Roles.Role;

    event PortfolioOwnerAdded(address indexed account);
    event PortfolioOwnerRemoved(address indexed account);
    event PortfolioMainOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    address private _owner;
    Roles.Role private portfolioOwners;

    modifier onlyMainPortfolioOwner() {
        require(
            isPortfolioMainOwner(msg.sender),
            "PortfolioOwnerRole: caller does not have a portfolio owner role"
        );
        _;
    }

    modifier onlyPortfolioOwner() {
        require(
            isPortfolioOwner(msg.sender),
            "PortfolioOwnerRole: caller does not have a portfolio owner role"
        );
        _;
    }

    /**
     * Initialize the contract.
     * First account is the main owner.
     * @param _portfolioOwners accounts that are owners of the portfolio
     */
    function initialize(address[] memory _portfolioOwners) public initializer {
        require(
            _portfolioOwners.length >= 0,
            "PortfolioOwnerRole: There must be at least one portfolio owner"
        );
        //First account is the main owner.
        _owner = _portfolioOwners[0];
        // Initializing portfolio owners.
        for (uint256 i = 0; i < _portfolioOwners.length; i++) {
            if (!portfolioOwners.has(_portfolioOwners[i])) {
                portfolioOwners.add(_portfolioOwners[i]);
            }
        }
    }

    /**
     * @dev Returns the address of the current main porfolio owner.
     */
    function portfolioMainOwner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns true if the caller is the current main porfolio owner.
     */
    function isPortfolioMainOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renouncePortfolioMainOwnership() public onlyMainPortfolioOwner {
        emit PortfolioMainOwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferPortfolioMainOwnership(address newOwner)
        public
        onlyMainPortfolioOwner
    {
        _transferPortfolioMainOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferPortfolioMainOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit PortfolioMainOwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * Returns true if the account is a portfolio owner.
     * @param _account account address.
     */
    function isPortfolioOwner(address _account) public view returns (bool) {
        return portfolioOwners.has(_account);
    }

    /**
     * Add portofolio owner role. Only main owner can execute it.
     * @param _account account address.
     */
    function addPortfolioOwner(address _account) public onlyMainPortfolioOwner {
        portfolioOwners.add(_account);
        emit PortfolioOwnerAdded(_account);
    }

    /**
     * Remove portofolio owner role. Only main owner can execute it.
     * @param _account account address.
     */
    function removePortfolioOwner(address _account)
        public
        onlyMainPortfolioOwner
    {
        portfolioOwners.remove(_account);
        emit PortfolioOwnerRemoved(_account);
    }
}
