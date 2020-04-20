pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol";


/**
 * @title ManagerRole
 * @dev Manager can operate the fund or portfolio.
 */
contract ManagerRole is Initializable {
    using Roles for Roles.Role;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);
    event MainManagerOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    address private _owner;
    Roles.Role private managers;

    modifier onlyMainManager() {
        require(
            isMainManager(msg.sender),
            "ManagerRole: caller does not have a main manager role"
        );
        _;
    }

    modifier onlyManager() {
        require(
            isManager(msg.sender),
            "ManagerRole: caller does not have a manager role"
        );
        _;
    }

    /**
     * Initialize the contract.
     * First account is the main owner.
     * @param _managers accounts that are managers
     */
    function initialize(address[] memory _managers) public initializer {
        require(
            _managers.length >= 0,
            "ManagerRole: There must be at least one manager"
        );
        //First account is the main owner.
        _owner = _managers[0];
        // Initializing portfolio owners.
        for (uint256 i = 0; i < _managers.length; i++) {
            if (!managers.has(_managers[i])) {
                managers.add(_managers[i]);
            }
        }
    }

    /**
     * @dev Returns the address of the current main manager.
     */
    function mainManager() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns true if the caller is the current main manager.
     */
    function isMainManager(address account) public view returns (bool) {
        return account == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceMainManagerOwnership() public onlyMainManager {
        emit MainManagerOwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferMainManagerOwnership(address newOwner)
        public
        onlyMainManager
    {
        _transferMainManagerOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferMainManagerOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit MainManagerOwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * Returns true if the account is a portfolio owner.
     * @param _account account address.
     */
    function isManager(address _account) public view returns (bool) {
        return managers.has(_account);
    }

    /**
     * Add portofolio owner role. Only main owner can execute it.
     * @param _account account address.
     */
    function addManager(address _account) public onlyMainManager {
        managers.add(_account);
        emit ManagerAdded(_account);
    }

    /**
     * Remove portofolio owner role. Only main owner can execute it.
     * @param _account account address.
     */
    function removeManager(address _account) public onlyMainManager {
        managers.remove(_account);
        emit ManagerRemoved(_account);
    }
}
