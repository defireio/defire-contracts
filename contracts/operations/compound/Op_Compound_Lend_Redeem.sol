pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./ICToken.sol";
import "../../base/IOperation.sol";


contract Op_Compound_Lend_Redeem is IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(uint256 amountInAsset, uint256 amountOutAsset);

    address public inAsset;
    address public outAsset;
    bool public isLend; //true if lend, false if redeem

    constructor(address _inAsset, address _outAsset, bool _isLend) public {
        inAsset = _inAsset;
        outAsset = _outAsset;
        isLend = _isLend;
        if (isLend) {
            approveToken();
        }
    }

    function approveToken() private {
        IERC20(inAsset).approve(outAsset, uint256(-1));
    }

    /**
     * Execute the operation.
     * @param _params params is the amount of inAsset to convert to outAsset
     */
    function operate(bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        require(msg.value == 0, "This operation does not receive ethers");

        //Get total balance of in asset, some may come from other operations
        uint256 finalAmountInAsset = IERC20(inAsset).balanceOf(address(this));

        //Execute operation
        if (isLend) {
            require(
                ICToken(outAsset).mint(finalAmountInAsset) == 0,
                "operation failed"
            );
        } else {
            require(
                ICToken(outAsset).redeem(finalAmountInAsset) == 0,
                "operation failed"
            );
        }

        require(
            IERC20(inAsset).balanceOf(address(this)) == 0,
            "in asset remainder"
        );

        //Send out assets back
        uint256 amountOutAsset = IERC20(outAsset).balanceOf(address(this));
        IERC20(outAsset).transfer(msg.sender, amountOutAsset);
        require(
            IERC20(outAsset).balanceOf(address(this)) == 0,
            "out asset remainder"
        );

        emit OperationExecuted(finalAmountInAsset, amountOutAsset);

        //Returns out assets amounts
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountOutAsset;
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
     * Returns the assets that the operation returns.
     * @param _params params of the operation.
     */
    function getOutAssets(bytes calldata _params)
        external
        view
        returns (address[] memory)
    {
        address[] memory _assets = new address[](1);
        _assets[0] = address(outAsset);
        return _assets;
    }
}
