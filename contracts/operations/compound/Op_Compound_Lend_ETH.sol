pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./ICEth.sol";
import "../../base/IOperation.sol";


contract Op_Compound_Lend_ETH is IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(uint256 amountETH, uint256 amountCETH);

    address public ETH;
    address public cETH;

    constructor() public {
        ETH = address(0);
        cETH = address($(CETH));
    }

    /**
     * Execute the operation.
     * @param _params params is the amount of ETH to convert to CETH
     */
    function operate(bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        //Get total balance of ETH, some may come from other operations
        uint256 finalAmountETH = address(this).balance;

        //Execute operation
        ICEth(cETH).mint.value(finalAmountETH)();
        require(address(this).balance == 0, "ETH remainder");

        //Send out assets back
        uint256 amountCETH = IERC20(cETH).balanceOf(address(this));
        IERC20(cETH).transfer(msg.sender, amountCETH);
        require(IERC20(cETH).balanceOf(address(this)) == 0, "CETH remainder");

        emit OperationExecuted(finalAmountETH, amountCETH);

        //Returns out assets amounts
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountCETH;
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
        _assets[0] = address(cETH);
        return _assets;
    }
}
