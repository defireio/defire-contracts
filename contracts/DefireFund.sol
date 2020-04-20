pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/upgrades/contracts/application/App.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./base/IOperation.sol";
import "./base/Operable.sol";
import "./base/FundToken.sol";
import "./registry/AssetRegistry.sol";
import "./registry/FundRegistry.sol";
import "./registry/OperationRegistry.sol";
import "./roles/ManagerRole.sol";


/**
 * @title DefireFund
 * @dev DefireFund is a contract that represents a fund for DeFi assets,
 * allowing fund managers to operate those assets.
 */
contract DefireFund is
    Initializable,
    Context,
    Operable,
    ManagerRole,
    IOperation
{
    using SafeMath for uint256;

    event OperationExecuted(bool isDeposit);
    event FundOperationExecuted(Operation operation);
    event FundOperationsExecuted(Operation[] operations);

    string public constant NAME = "Defire Fund";
    string public constant VERSION = "1.0.0";
    FundToken private token;

    /**
     * Initialize the contract.
     * @param _app application.
     * @param _managers accounts that can operate the fund.
     * @param _operations whitelisted operations list.
     * @param _assets whitelisted assets list.
     * @param _fundRegistry registry contracts address of funds.
     * @param _operationRegistry registry contract address of operations.
     * @param _assetRegistry registry contract address of assets.
     */
    function initialize(
        App _app,
        address[] memory _managers,
        address[] memory _operations,
        address[] memory _assets,
        FundRegistry _fundRegistry,
        OperationRegistry _operationRegistry,
        AssetRegistry _assetRegistry
    ) public initializer {
        ManagerRole.initialize(_managers);
        Operable.initialize(
            _operations,
            _assets,
            _fundRegistry,
            _operationRegistry,
            _assetRegistry
        );
        createFundToken(_app);
    }

    /**
     * Creates an ERC20 token to represent shares of the fund.
     * @param _app contract for the upgradeable application.
     */
    function createFundToken(App _app) private returns (address) {
        string memory packageName = "defire";
        string memory contractName = "FundToken";
        address admin = msg.sender;
        bytes memory data = abi.encodeWithSignature(
            "initialize(address)",
            address(this)
        );
        token = FundToken(
            address(_app.create(packageName, contractName, admin, data))
        );
    }

    /**
     * Execute a set of operations secuencially. Only managers can execute them.
     * @param _operations array of operations to be executed.
     */
    function executeOperations(Operation[] memory _operations)
        public
        onlyManager
    {
        _executeMultipleOperations(_operations, true);
        emit FundOperationsExecuted(_operations);
    }

    /**
     * Execute an operation. Only manager can execute.
     * @param _operation operation to execute.
     */
    function executeOperation(Operation memory _operation) public onlyManager {
        _executeSingleOperation(_operation, true);
        emit FundOperationExecuted(_operation);
    }

    /**
     * Deposit ERC20 tokens in the fund.
     * It has to deposit same proportonial amounts for each token of the fund.
     * It mints and send the fund token to the sender.
     * @param _assets assets to deposit.
     * @param _amounts amounts of assets to deposit.
     */
    function deposit(address[] memory _assets, uint256[] memory _amounts)
        internal
    {
        address[] memory currentAssets = getAssets();
        if (currentAssets.length == 0) {
            //Can deposit any valid asset
            uint256 sum = 0;
            for (uint256 i = 0; i < _assets.length; i++) {
                checkValidAsset(_assets[i]);
                IERC20(_assets[i]).transferFrom(
                    msg.sender,
                    address(this),
                    _amounts[i]
                );
                sum = sum.add(_amounts[i]);
            }
            //Mint tokens to sender. For an intial value reference, it mints the sum of amounts.
            token.mint(msg.sender, sum);
        } else {
            //Has to deposit existing assets
            require(
                assets.length == currentAssets.length,
                "DefireFund: must deposit the same assets than the funds."
            );
            //Calculate the share. It is checked that there is at least one asset in params
            uint256 share = _amounts[0].mul(1 ether).div(
                IERC20(_assets[0]).balanceOf(address(this))
            );
            for (uint256 i = 0; i < _assets.length; i++) {
                require(
                    assets[i] == currentAssets[i],
                    "DefireFund: assets to deposit must be in the right order that getAssets()"
                );
                //Check it is the right share
                uint256 amountToDeposit = IERC20(_assets[i])
                    .balanceOf(address(this))
                    .mul(share)
                    .div(1 ether);
                require(
                    amountToDeposit <= _amounts[i],
                    "DefireFund: not enough amount to deposit"
                );
                IERC20(_assets[i]).transferFrom(
                    msg.sender,
                    address(this),
                    amountToDeposit
                );
            }
            //Mint tokens to sender
            token.mint(msg.sender, token.totalSupply().mul(share).div(1 ether));
        }
    }

    /**
     * Withdraw ERC20 tokens from the fund.
     * It withdraws each token of the fund in proportonial amounts to the fund token amount received.
     * It receives and burns the fund token.
     * @param _amount amount of fund token to deposit.
     */
    function withdraw(uint256 _amount) internal {
        address[] memory fundAssets = getAssets();
        require(
            fundAssets.length > 0,
            "DefireFund: Fund does not contain any asset"
        );
        uint256 totalTokens = token.totalSupply();
        uint256 share = _amount.mul(1 ether).div(totalTokens);
        token.transferFrom(msg.sender, address(this), _amount);
        token.burn(_amount);
        for (uint256 i = 0; i < fundAssets.length; i++) {
            address asset = fundAssets[i];
            uint256 amount = IERC20(asset)
                .balanceOf(address(this))
                .mul(share)
                .div(1 ether);
            IERC20(asset).transfer(msg.sender, amount);
        }
    }

    /**
     * Execute the withdraw or deposit operation.
     * @param _inAmounts amounts of assets in.
     * @param _params params of the operation.
     */
    function operate(uint256[] calldata _inAmounts, bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        require(
            msg.value == 0,
            "DefireFund: does not receive ethers, use WETH instead"
        );
        if (isDeposit(_params)) {
            address[] memory assets = getAssetsToDeposit(_params);
            require(
                assets.length == _inAmounts.length,
                "DefireFund: number of amounts does not match number of assets"
            );
            deposit(assets, _inAmounts);
            emit OperationExecuted(true);
            return _inAmounts;
        } else {
            require(
                _inAmounts.length == 1,
                "DefireFund: neet to set only the amount of fund token used to withdraw"
            );
            withdraw(_inAmounts[0]);
            emit OperationExecuted(false);

            return _inAmounts;
        }
    }

    /**
     * Returns the assets that the operation receives.
     * @param _params params of the operation.
     */
    function getInAssets(bytes calldata _params)
        external
        view
        returns (address[] memory)
    {
        address[] memory _assets;
        if (isDeposit(_params)) {
            if (getTotalAssets() == 0) {
                return getAssetsToDeposit(_params);
            } else {
                return getAssets();
            }
        } else {
            //Returns fund token
            _assets = new address[](1);
            _assets[0] = address(token);
            return _assets;
        }
    }

    /**
     * Returns the assets that the operation returns.
     * @param _params params of the operation.
     */
    function getOutAssets(bytes calldata _params)
        external
        view
        returns (address[] memory)
    {
        address[] memory _assets;
        if (isDeposit(_params)) {
            //Returns fund token
            _assets = new address[](1);
            _assets[0] = address(token);
            return _assets;
        } else {
            if (getTotalAssets() == 0) {
                address[] memory empty;
                return empty;
            } else {
                return getAssets();
            }
        }
    }

    /**
     * Returns true if operation is deposit.
     * @param _params params of the operation.
     */
    function isDeposit(bytes memory _params) public pure returns (bool) {
        return abi.decode(_params, (bool));
    }

    /**
     * Returns the assets to deposit.
     * @param _params params of the operation.
     */
    function getAssetsToDeposit(bytes memory _params)
        public
        pure
        returns (address[] memory assets)
    {
        (, assets) = abi.decode(_params, (bool, address[]));
    }

    /**
     * Returns the token of the fund
     */
    function getFundToken() public view returns (address) {
        return address(token);
    }
}
