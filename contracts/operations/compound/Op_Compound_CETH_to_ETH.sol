pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./ICEth.sol";
import "../../base/IOperation.sol";


contract Op_Compound_CETH_to_ETH is Initializable, IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(uint256 amoundCETH, uint256 amountETH);

    address public ETH;
    address public cETH;

    function initialize() public initializer {
        ETH = address($(ETH));
        cETH = address($(CETH));
    }

    /**
     * Fallback function accepts Ether transactions.
     */
    function() external payable {}

    /**
     * Execute the operation.
     * @param _inAmounts amounts of assets in.
     * @param _params params is the amount to convert to CETH
     */
    function operate(uint256[] calldata _inAmounts, bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        require(msg.value == 0, "This operation does not receive ethers");

        //In assets amounts
        require(_inAmounts.length != 0, "Need to set CETH amount");
        uint256 amountCETH = _inAmounts[0];

        //Get in assets
        if (amountCETH > 0) {
            IERC20(cETH).transferFrom(msg.sender, address(this), amountCETH);
        }

        //Get total balance of CETH, some may come from other operations
        uint256 finalAmountCETH = IERC20(cETH).balanceOf(address(this));

        //Execute operation
        require(ICEth(cETH).redeem(finalAmountCETH) == 0, "operation failed");
        require(IERC20(cETH).balanceOf(address(this)) == 0, "CETH remainder");

        //Send out assets back
        uint256 ethBalance = address(this).balance;
        msg.sender.transfer(ethBalance);
        require(address(this).balance == 0, "ETH remainder");

        emit OperationExecuted(finalAmountCETH, ethBalance);

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
        _assets[0] = address(cETH);
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
        _assets[0] = address(ETH);
        return _assets;
    }
}
