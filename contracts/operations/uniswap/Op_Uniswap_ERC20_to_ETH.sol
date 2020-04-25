pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./IUniswap.sol";
import "../../base/IOperation.sol";


contract Op_Uniswap_ERC20_to_ETH is IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(
        uint256 amountInAsset,
        uint256 minEth,
        uint256 deadline,
        uint256 amountETH
    );

    address public inAsset;
    address public exchange;
    address public ETH;

    constructor(address _inAsset, address _exchange) public {
        inAsset = _inAsset;
        exchange = _exchange;
        ETH = address(0);
        approveToken();
    }

    /**
     * Fallback function accepts Ether transactions.
     */
    function() external payable {}

    function approveToken() private {
        IERC20(inAsset).approve(exchange, uint256(-1));
    }

    /**
     * Decode the params of the operation.
     * @param _params params of the operation.
     */
    function getParams(bytes memory _params)
        public
        pure
        returns (uint256 minEth, uint256 deadline)
    {
        (minEth, deadline) = abi.decode(_params, (uint256, uint256));
    }

    /**
     * Execute the operation.
     * @param _inAmounts amounts of assets in.
     * @param _params params is the amount of in asset to swap to ETH, the min amount of ETH to get and the deadline
     */
    function operate(uint256[] calldata _inAmounts, bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        require(msg.value == 0, "This operation does not receive ethers");

        //In assets amounts
        require(_inAmounts.length != 0, "Need to set in asset amount");
        uint256 amountInAsset = _inAmounts[0];

        //Get params
        uint256 minEth;
        uint256 deadline;
        (minEth, deadline) = getParams(_params);

        //Get in assets
        if (amountInAsset > 0) {
            IERC20(inAsset).transferFrom(
                msg.sender,
                address(this),
                amountInAsset
            );
        }

        //Get total balance of in asset, some may come from other operations
        uint256 finalAmountInAsset = IERC20(inAsset).balanceOf(address(this));

        //Execute operation
        require(
            IUniswap(exchange).tokenToEthSwapInput(
                finalAmountInAsset,
                minEth,
                deadline
            ) > 0,
            "operation failed"
        );
        require(
            IERC20(inAsset).balanceOf(address(this)) == 0,
            "In asset remainder"
        );

        //Send out assets back
        uint256 ethBalance = address(this).balance;
        Address.sendValue(msg.sender, ethBalance);
        require(address(this).balance == 0, "ETH remainder");

        emit OperationExecuted(
            finalAmountInAsset,
            minEth,
            deadline,
            ethBalance
        );

        //Returns out assets amounts
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ethBalance;
        return amounts;
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
        address[] memory _assets = new address[](1);
        _assets[0] = address(inAsset);
        return _assets;
    }

    /**
     * Returns the assets that the operation returns. 0x0 address for ETH
     * @param _params params of the operation.
     */
    function getOutAssets(bytes calldata _params)
        external
        view
        returns (address[] memory)
    {
        address[] memory _assets = new address[](1);
        _assets[0] = ETH;
        return _assets;
    }
}
