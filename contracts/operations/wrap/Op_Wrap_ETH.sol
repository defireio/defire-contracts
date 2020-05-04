pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../common/IWETH.sol";
import "../../base/IOperation.sol";


contract Op_Wrap_ETH is IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(uint256 amountETH);

    address public ETH;
    address public WETH;

    constructor() public {
        ETH = address(0);
        WETH = address($(WETH));
    }

    /**
     * Execute the operation.
     * @param _params params is the amount of ETH to wrap
     */
    function operate(uint256[] calldata _inAmounts, bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        //Get total balance of ETH, some may come from other operations
        uint256 finalAmountETH = address(this).balance;

        //Execute operation
        IWETH(WETH).deposit.value(finalAmountETH)();
        require(
            IERC20(WETH).balanceOf(address(this)) == finalAmountETH &&
                address(this).balance == 0,
            "Failed to wrap"
        );

        //Send out assets back
        IERC20(WETH).transfer(msg.sender, finalAmountETH);
        require(IERC20(WETH).balanceOf(address(this)) == 0, "WETH remainder");

        emit OperationExecuted(finalAmountETH);

        //Returns out assets amounts
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = finalAmountETH;
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
        _assets[0] = address(ETH);
        return _assets;
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
        address[] memory _assets = new address[](1);
        _assets[0] = address(WETH);
        return _assets;
    }
}
