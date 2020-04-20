pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/application/App.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "../registry/AssetRegistry.sol";
import "../registry/FundRegistry.sol";
import "../registry/OperationRegistry.sol";

/**
 * @title FundFactory
 * @dev Factory of funds.
 */
contract FundFactory is Initializable, Context {
    App private app;
    FundRegistry fundRegistry;
    OperationRegistry operationRegistry;
    AssetRegistry assetRegistry;

    event FundCreated(address, address[], address[], address[]);

    /**
     * Initialize the contract.
     * @param _app application.
     * @param _fundRegistry registry contracts address of funds.
     * @param _operationRegistry registry contract address of operations.
     * @param _assetRegistry registry contract address of assets.
     */
    function initialize(
        App _app,
        FundRegistry _fundRegistry,
        OperationRegistry _operationRegistry,
        AssetRegistry _assetRegistry
    ) public initializer {
        app = _app;
        fundRegistry = _fundRegistry;
        operationRegistry = _operationRegistry;
        assetRegistry = _assetRegistry;
    }

    /**
     * Create new portfolio instance.
     * @param _managers accounts that can operate the fund.
     * @param _operations whitelisted operations list.
     * @param _assets whitelisted assets list.
     */
    function createInstance(
        address[] memory _managers,
        address[] memory _operations,
        address[] memory _assets
    ) public {
        string memory packageName = "defire";
        string memory contractName = "DefireFund";
        bytes memory _data = abi.encodeWithSignature(
            "initialize(address,address[],address[],address[],address,address,address)",
            app,
            _managers,
            _operations,
            _assets,
            fundRegistry,
            operationRegistry,
            assetRegistry
        );
        address fund = address(
            app.create(packageName, contractName, address(this), _data)
        );
        //Save fund in registry
        fundRegistry.addElement(fund);

        emit FundCreated(fund, _managers, _operations, _assets);
    }
}
