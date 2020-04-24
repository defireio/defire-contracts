pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./ICToken.sol";
import "../../base/IOperation.sol";


contract Op_Compound_DAI_to_CDAI is Initializable, IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(uint256 amoundDAI, uint256 amountCDAI);

    address public DAI;
    address public cDAI;

    function initialize() public initializer {
        DAI = address($(DAI));
        cDAI = address($(CDAI));
        approveToken();
    }

    function approveToken() private {
        IERC20(DAI).approve(cDAI, uint256(-1));
    }

    /**
     * Execute the operation.
     * @param _inAmounts amounts of assets in.
     * @param _params params is the amount of DAI to convert to CDAI
     */
    function operate(uint256[] calldata _inAmounts, bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        require(msg.value == 0, "This operation does not receive ethers");

        //In assets amounts
        require(_inAmounts.length != 0, "Need to set DAI amount");
        uint256 amountDAI = _inAmounts[0];

        //Get in assets
        if (amountDAI > 0) {
            IERC20(DAI).transferFrom(msg.sender, address(this), amountDAI);
        }

        //Get total balance of DAI, some may come from other operations
        uint256 finalAmountDAI = IERC20(DAI).balanceOf(address(this));

        //Execute operation
        require(ICToken(cDAI).mint(finalAmountDAI) == 0, "operation failed");
        require(IERC20(DAI).balanceOf(address(this)) == 0, "dai remainder");

        //Send out assets back
        uint256 amountCDAI = IERC20(cDAI).balanceOf(address(this));
        IERC20(cDAI).transfer(msg.sender, amountCDAI);
        require(IERC20(cDAI).balanceOf(address(this)) == 0, "cdai remainder");

        emit OperationExecuted(finalAmountDAI, amountCDAI);

        //Returns out assets amounts
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountCDAI;
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
        _assets[0] = address(DAI);
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
        _assets[0] = address(cDAI);
        return _assets;
    }
}
