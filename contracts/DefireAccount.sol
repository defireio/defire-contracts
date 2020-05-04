pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./base/Operable.sol";
import "./registry/AssetRegistry.sol";
import "./registry/FundRegistry.sol";
import "./registry/OperationRegistry.sol";


/**
 * @title DefireAccount
 * @dev DefireAccount is a contract to execute one or multiple DeFi operations from an account
 */
contract DefireAccount is Initializable, Operable {
    string public constant NAME = "Defire Account";
    string public constant VERSION = "1.0.0";

    event AccountOperationExecuted(Operation operation, bool checkSafe);
    event AccountOperationsExecuted(Operation[] _operations, bool _checkSafe);

    /**
     * Initialize the contract.
     * @param _fundRegistry registry contracts address of funds.
     * @param _operationRegistry registry contract address of operations.
     * @param _assetRegistry registry contract address of assets.
     */
    function initialize(
        FundRegistry _fundRegistry,
        OperationRegistry _operationRegistry,
        AssetRegistry _assetRegistry
    ) public initializer {
        Operable.initialize(
            new address[](0),
            new address[](0),
            _fundRegistry,
            _operationRegistry,
            _assetRegistry
        );
    }

    /**
     * Fallback function accepts Ether transactions.
     */
    function() external payable {}

    /**
     * Execute a set of operations secuencially..
     * @param _operations array of operations to be executed.
     * @param _checkSafe check if operations is official (in registry).
     */
    function executeOperations(Operation[] memory _operations, bool _checkSafe)
        public
        payable
    {
        _executeMultipleOperations(_operations, _checkSafe, true);
        emit AccountOperationsExecuted(_operations, _checkSafe);
    }

    /**
     * Execute an operation..
     * @param _operation operation to execute.
     * @param _checkSafe check if operations is official (in registry).
     */
    function executeOperation(Operation memory _operation, bool _checkSafe)
        public
        payable
    {
        _executeSingleOperation(_operation, _checkSafe, true);
        emit AccountOperationExecuted(_operation, _checkSafe);
    }

}
