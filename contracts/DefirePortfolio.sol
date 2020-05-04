pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./base/Operable.sol";
import "./registry/AssetRegistry.sol";
import "./registry/FundRegistry.sol";
import "./registry/OperationRegistry.sol";
import "./roles/ManagerRole.sol";
import "./roles/PortfolioOwnerRole.sol";


/**
 * @title DefirePortfolio
 * @dev DefirePortfolio is a contract for that represent a portfolio,
 * It allows owners to deposit and withdraw their ether or ERC20 tokens to it,
 * and owners and managers to operate it.
 */
contract DefirePortfolio is
    Initializable,
    Context,
    Operable,
    ManagerRole,
    PortfolioOwnerRole
{
    string public constant NAME = "Defire Portfolio";
    string public constant VERSION = "1.0.0";

    event PortfolioOperationExecuted(Operation operation);
    event PortfolioOperationsExecuted(Operation[] _operations);
    event PortfolioWithdrawn(address[] assets, uint256[] amounts, address to);

    /**
     * Initialize the contract.
     * @param _owners accounts that are owners of the portfolio.
     * @param _managers accounts that can operate the portfolio.
     * @param _operations whitelisted operations list.
     * @param _assets whitelisted assets list.
     * @param _fundRegistry registry contracts address of funds.
     * @param _operationRegistry registry contract address of operations.
     * @param _assetRegistry registry contract address of assets.
     */
    function initialize(
        address[] memory _owners,
        address[] memory _managers,
        address[] memory _operations,
        address[] memory _assets,
        FundRegistry _fundRegistry,
        OperationRegistry _operationRegistry,
        AssetRegistry _assetRegistry
    ) public initializer {
        PortfolioOwnerRole.initialize(_owners);
        ManagerRole.initialize(_managers);
        Operable.initialize(
            _operations,
            _assets,
            _fundRegistry,
            _operationRegistry,
            _assetRegistry
        );
    }

    modifier onlyPortfolioOwnerOrManager() {
        require(
            isPortfolioOwner(msg.sender) || isManager(msg.sender),
            "DefirePortfolio: caller is not portfolio owner or manager"
        );
        _;
    }

    /**
     * Fallback function accepts Ether transactions.
     */
    function() external payable {}

    /**
     * Execute a set of operations secuencially. Only managers can execute them.
     * @param _operations array of operations to be executed.
     */
    function executeOperations(Operation[] memory _operations)
        public
        onlyPortfolioOwnerOrManager
    {
        _executeMultipleOperations(_operations, true, false);
        emit PortfolioOperationsExecuted(_operations);
    }

    /**
     * Execute an operation. Only manager can execute.
     * @param _operation operation to execute.
     */
    function executeOperation(Operation memory _operation)
        public
        onlyPortfolioOwnerOrManager
    {
        _executeSingleOperation(_operation, true, false);
        emit PortfolioOperationExecuted(_operation);
    }

    /**
     * Transfer tokens to one of the owners.
     * @param _assets array of tokens to transfer.
     * @param _amounts array of amounts to transfer.
     * @param _to owner address to transfer.
     */
    function withdraw(
        address[] memory _assets,
        uint256[] memory _amounts,
        address payable _to
    ) public onlyPortfolioOwnerOrManager {
        require(
            isPortfolioOwner(_to),
            "DefirePortfolio: Invalid portfolio owner to withdraw"
        );
        require(
            _assets.length == _amounts.length,
            "DefirePortfolio: Not equal amount of assets and amounts"
        );
        for (uint8 i = 0; i < _assets.length; i++) {
            if (_assets[i] == address(0)) {
                Address.sendValue(_to, _amounts[i]);
            } else {
                IERC20(_assets[i]).transfer(_to, _amounts[i]);
            }
        }
        emit PortfolioWithdrawn(_assets, _amounts, _to);
    }
}
