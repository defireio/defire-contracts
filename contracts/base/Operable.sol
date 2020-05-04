pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./IOperation.sol";
import "./AssetManager.sol";
import "../registry/FundRegistry.sol";
import "../registry/OperationRegistry.sol";
import "../registry/AssetRegistry.sol";


/**
 * @title Operable
 * @dev Operable is a base contract for operating assets (ERC20 tokens) of a contract.
 * Accounts with manager roles canoperate it.
 * It only execute valid operations from the OperationReegistry.
 */
contract Operable is Initializable, AssetManager {
    using SafeMath for uint256;

    struct OutAmount {
        address asset;
        uint256 amount;
        bool isPercentage;
        address payable to;
    }

    struct Operation {
        address addr;
        uint256[] inAmounts;
        OutAmount[] outAmounts;
        bytes params;
    }

    bool operationsWhitelist;
    mapping(address => bool) operationWhitelisted;
    OperationRegistry operationRegistry;

    /**
     * Initialize the contract.
     * @param _operations whitelisted operations list.
     * @param _assets whitelisted assets list.
     * @param _fundRegistry registry contracts address of funds.
     * @param _operationRegistry registry contract address of operations.
     * @param _assetRegistry registry contract address of assets.
     */
    function initialize(
        address[] memory _operations,
        address[] memory _assets,
        FundRegistry _fundRegistry,
        OperationRegistry _operationRegistry,
        AssetRegistry _assetRegistry
    ) public initializer {
        operationsWhitelist = _operations.length > 0;
        for (uint256 i = 0; i < _operations.length; i++) {
            operationWhitelisted[_operations[i]] = true;
        }
        AssetManager.initialize(_assets, _fundRegistry, _assetRegistry);
        fundRegistry = _fundRegistry;
        operationRegistry = _operationRegistry;
    }

    /**
     * Execute an operation.
     * @param _operation operation to execute.
     * @param _checkSafe check if operations is official (in registry or whitelist).
     * @param _assetsFromSender true if assets must be transferred from sender.
     */
    function _executeSingleOperation(
        Operation memory _operation,
        bool _checkSafe,
        bool _assetsFromSender
    ) internal {
        _executeOperation(_operation, _checkSafe, _assetsFromSender);
    }

    /**
     * Execute a set of operations secuencially. Only managers can execute them.
     * @param _operations array of operations to be executed.
     * @param _checkSafe check if operations is official (in registry or whitelist).
     * @param _assetsFromSender true if assets must be transferred from sender.
     */
    function _executeMultipleOperations(
        Operation[] memory _operations,
        bool _checkSafe,
        bool _assetsFromSender
    ) internal {
        for (uint8 i = 0; i < _operations.length; i++) {
            _executeOperation(_operations[i], _checkSafe, _assetsFromSender);
        }
    }

    /**
     * Execute an operations.
     * @param _operation operation to execute.
     * @param _checkSafe check if operations is official (in registry or whitelist).
     * @param _assetsFromSender true if assets must be transferred from sender.
     */
    function _executeOperation(
        Operation memory _operation,
        bool _checkSafe,
        bool _assetsFromSender
    ) private {
        if (_checkSafe) {
            checkValidOperation(_operation.addr);
        }

        //Manage in assets
        address[] memory inAssets = IOperation(_operation.addr).getInAssets(
            _operation.params
        );
        require(
            _operation.inAmounts.length == inAssets.length,
            "The number of in amounts does not match the in assets of the operations"
        );
        uint256 ethersAmount = 0;
        for (uint8 i = 0; i < _operation.inAmounts.length; i++) {
            address asset = inAssets[i];
            //Check if operable manages that asset
            if (_checkSafe) {
                checkValidAsset(asset);
            }
            if (asset == address(0)) {
                ethersAmount = _operation.inAmounts[i];
            } else {
                if (_assetsFromSender) {
                    IERC20(asset).transferFrom(
                        msg.sender,
                        _operation.addr,
                        _operation.inAmounts[i]
                    );
                } else {
                    //Approve token transfer
                    IERC20(asset).transfer(
                        _operation.addr,
                        _operation.inAmounts[i]
                    );
                }
            }
        }

        uint256[] memory outputs;
        if (ethersAmount > 0) {
            outputs = IOperation(_operation.addr).operate.value(ethersAmount)(
                _operation.params
            );
        } else {
            outputs = IOperation(_operation.addr).operate(_operation.params);
        }

        _redirectOutputs(_operation, outputs, _checkSafe);

        if (_assetsFromSender) {
            //Transfer out assets to sender
            address[] memory outAssets = IOperation(_operation.addr)
                .getOutAssets(_operation.params);
            _transferAssetsToSender(outAssets);
        }
    }

    /**
     * Execute an operations.
     * @param _operation operation that redirects outputs.
     * @param _outputs operation outputs.
     * @param _checkSafe check if operations is official (in registry).
     */
    function _redirectOutputs(
        Operation memory _operation,
        uint256[] memory _outputs,
        bool _checkSafe
    ) private {
        //Manage out assets
        for (uint8 i = 0; i < _operation.outAmounts.length; i++) {
            OutAmount memory outAmount = _operation.outAmounts[i];
            //Check if operable manages that asset
            if (_checkSafe) {
                checkValidAsset(outAmount.asset);
            }
            //Get index
            uint256 assetIndex = getAssetIndex(outAmount.asset);
            //Assets can be moved only to other valid operations
            if (_checkSafe) {
                checkValidOperation(outAmount.to);
            }
            //Manage if fixed or percentage
            if (outAmount.isPercentage) {
                if (outAmount.asset == address(0)) {
                    Address.sendValue(
                        outAmount.to,
                        _outputs[assetIndex].mul(outAmount.amount).div(1 ether)
                    );
                } else {
                    uint256 total = _outputs[assetIndex]
                        .mul(outAmount.amount)
                        .div(1 ether);
                    IERC20(outAmount.asset).transfer(outAmount.to, total);
                }
            } else {
                require(
                    outAmount.amount < _outputs[assetIndex],
                    "Output amount less than the specified to redirect"
                );
                if (outAmount.asset == address(0)) {
                    Address.sendValue(outAmount.to, outAmount.amount);
                } else {
                    IERC20(outAmount.asset).transfer(
                        outAmount.to,
                        outAmount.amount
                    );
                }
            }
        }
    }

    /**
     * Check if operation is whitelisted or in registry
     * @param operation address of the operation.
     */
    function checkValidOperation(address operation) internal view {
        if (operationsWhitelist)
            require(operationWhitelisted[operation], "Invalid operation");
        else {
            require(
                operationRegistry.isElement(operation),
                "Invalid operation"
            );
        }
    }

    /**
     * Check if asset is whitelisted or in registry, and if the operation manages the asset
     * @param _asset address of the asset.
     */
    function checkValidAsset(address _asset) internal view {
        require(isAsset(_asset), "Invalid asset");
    }

    /**
     * Transfer all asset balance from this contract to sender.
     * @param _outAssets list of assets to transfer.
     */
    function _transferAssetsToSender(address[] memory _outAssets) private {
        //Manage in assets
        for (uint8 i = 0; i < _outAssets.length; i++) {
            address asset = _outAssets[i];
            if (asset != address(0)) {
                uint256 amount = IERC20(asset).balanceOf(address(this));
                IERC20(asset).transfer(msg.sender, amount);
            } else {
                uint256 ethBalance = address(this).balance;
                Address.sendValue(msg.sender, ethBalance);
            }
        }
    }
}
