pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./ICDAI.sol";
import "../../base/IOperation.sol";


contract Op_Compound_CDAI_to_DAI is Initializable, IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(uint256 amoundCDAI, uint256 amountDAI);

    address public DAI;
    address public cDAI;

    function initialize() public initializer {
        DAI = address($(DAI));
        cDAI = address($(CDAI));
    }

    /**
     * Execute the operation.
     * @param _inAmounts amounts of assets in.
     * @param _params params is the amount to convert to CDAI
     */
    function operate(uint256[] calldata _inAmounts, bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        require(msg.value == 0, "This operation does not receive ethers");

        //In assets amounts
        require(_inAmounts.length != 0, "Need to set CDAI amount");
        uint256 amountCDAI = _inAmounts[0];

        //Get in assets
        if (amountCDAI > 0) {
            IERC20(cDAI).transferFrom(msg.sender, address(this), amountCDAI);
        }

        //Get total balance of CDAI, some may come from other operations
        uint256 finalAmountCDAI = IERC20(cDAI).balanceOf(address(this));

        //Execute operation
        require(ICDAI(cDAI).redeem(finalAmountCDAI) == 0, "operation failed");
        require(IERC20(cDAI).balanceOf(address(this)) == 0, "cdai remainder");

        //Send out assets back
        uint256 amountDAI = IERC20(DAI).balanceOf(address(this));
        IERC20(DAI).transfer(msg.sender, amountDAI);
        require(IERC20(DAI).balanceOf(address(this)) == 0, "dai remainder");

        emit OperationExecuted(finalAmountCDAI, amountDAI);

        //Returns out assets amounts
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountDAI;
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
        _assets[0] = address(cDAI);
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
        _assets[0] = address(DAI);
        return _assets;
    }
}
