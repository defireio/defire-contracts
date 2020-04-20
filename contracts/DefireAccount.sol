pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

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
    event AccountOperationsExecuted(Operation[] _operations,  bool _checkSafe);

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
        for (uint8 i = 0; i < _operations.length; i++) {
            _transferAssetsFromSender(
                IOperation(_operations[i].addr).getInAssets(
                    _operations[i].params
                ),
                _operations[i].inAmounts
            );
        }
        _executeMultipleOperations(_operations, _checkSafe);
        for (uint8 i = 0; i < _operations.length; i++) {
            _transferAssetsToSender(
                IOperation(_operations[i].addr).getOutAssets(
                    _operations[i].params
                )
            );
        }
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
        _transferAssetsFromSender(
            IOperation(_operation.addr).getInAssets(_operation.params),
            _operation.inAmounts
        );
        _executeSingleOperation(_operation, _checkSafe);
        _transferAssetsToSender(
            IOperation(_operation.addr).getOutAssets(_operation.params)
        );
        emit AccountOperationExecuted(_operation, _checkSafe);
    }

    /**
     * Transfer assets from sender to this contract.
     * @param _inAssets list of assets to transfer.
     * @param _inAmounts list of assets to transfer.
     */
    function _transferAssetsFromSender(
        address[] memory _inAssets,
        uint256[] memory _inAmounts
    ) private {
        //Manage in assets
        for (uint8 i = 0; i < _inAmounts.length; i++) {
            address asset = _inAssets[i];
            if (asset != address(0)) {
                //Get tokens from account
                IERC20(asset).transferFrom(
                    msg.sender,
                    address(this),
                    _inAmounts[i]
                );
            }
        }
    }

    /**
     * Transfer all asset balance from this contract to sender.
     * @param _inAssets list of assets to transfer.
     */
    function _transferAssetsToSender(address[] memory _inAssets) private {
        //Manage in assets
        for (uint8 i = 0; i < _inAssets.length; i++) {
            address asset = _inAssets[i];
            if (asset != address(0)) {
                uint256 amount = IERC20(asset).balanceOf(address(this));
                IERC20(asset).transfer(msg.sender, amount);
            } else {
                uint256 ethBalance = address(this).balance;
                msg.sender.transfer(ethBalance);
            }
        }
    }
}
