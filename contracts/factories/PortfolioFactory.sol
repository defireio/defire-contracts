pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/application/App.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "../registry/AssetRegistry.sol";
import "../registry/FundRegistry.sol";
import "../registry/OperationRegistry.sol";

/**
 * @title PortfolioFactory
 * @dev Factory of portfolios.
 */
contract PortfolioFactory is Initializable, Context {
    App private app;
    FundRegistry fundRegistry;
    OperationRegistry operationRegistry;
    address assetRegistry;

    event PortfolioCreated(address, address[], address[], address[], address[]);

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
        address _assetRegistry
    ) public initializer {
        app = _app;
        fundRegistry = _fundRegistry;
        operationRegistry = _operationRegistry;
        assetRegistry = _assetRegistry;
    }

    /**
     * Create new portfolio instance.
     * @param _owners accounts that are owners of the portfolio.
     * @param _managers accounts that can operate the portfolio.
     * @param _operations whitelisted operations list.
     * @param _assets whitelisted assets list.
     */
    function createInstance(
        address[] memory _owners,
        address[] memory _managers,
        address[] memory _operations,
        address[] memory _assets
    ) public {
        string memory packageName = "defire";
        string memory contractName = "DefirePortfolio";
        bytes memory _data = abi.encodeWithSignature(
            "initialize(address[],address[],address[],address[],address,address,address)",
            _owners,
            _managers,
            _operations,
            _assets,
            fundRegistry,
            operationRegistry,
            assetRegistry
        );
        address portfolio = address(
            app.create(packageName, contractName, address(this), _data)
        );

        emit PortfolioCreated(
            portfolio,
            _owners,
            _managers,
            _operations,
            _assets
        );
    }
}
