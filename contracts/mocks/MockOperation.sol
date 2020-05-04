pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../base/IOperation.sol";


/**
 * @title MockOperation
 * @dev Operation to make tests
 */
contract MockOperation is IOperation {
    using SafeMath for uint256;

    event OperationExecuted(uint256[] inAmounts, uint256[] outAmounts);

    string name;
    uint8 times;
    uint8 divisor;
    address[] inAssets;
    address[] outAssets;

    constructor(
        string memory _name,
        address[] memory _inAssets,
        address[] memory _outAssets,
        uint8 _times,
        uint8 _divisor
    ) public {
        name = _name;
        times = _times;
        divisor = _divisor;
        inAssets = _inAssets;
        outAssets = _outAssets;
    }

    function() external payable {}

    //Operation
    function operate(bytes calldata params)
        external
        payable
        returns (uint256[] memory)
    {
        uint256[] memory inAmounts = new uint256[](inAssets.length);
        for (uint8 i = 0; i < inAssets.length; i++) {
            address asset = inAssets[i];
            if (asset != address(0)) {
                inAmounts[i] = IERC20(asset).balanceOf(address(this));
                //Clean assets for next time
                 IERC20(asset).transfer(address(1), inAmounts[i]);
            } else {
                inAmounts[i] = address(this).balance;
                Address.sendValue(address(1), inAmounts[i]);
            }
        }

        uint256[] memory totals = new uint256[](outAssets.length);
        for (uint8 i = 0; i < outAssets.length; i++) {
            address asset = outAssets[i];
            uint256 total;
            if (asset != address(0)) {
                total = inAmounts[0].mul(times).div(divisor);
                IERC20(asset).transfer(msg.sender, total);
                emit OperationExecuted(inAmounts, totals);
                totals[i] = total;
            } else {
                total = inAmounts[0].mul(times).div(divisor);
                Address.sendValue(msg.sender, total);
                emit OperationExecuted(inAmounts, totals);
                totals[i] = total;
            }
            return totals;
        }
        return totals;
    }

    /**
     * Decode the params of the operation.
     * @param _params params of the operation.
     */
    function getParams(bytes memory _params)
        public
        pure
        returns (uint256 min, uint256 deadline)
    {
        (min, deadline) = abi.decode(_params, (uint256, uint256));
    }

    function getInAssets(bytes calldata params)
        external
        view
        returns (address[] memory)
    {
        return inAssets;
    }

    function getOutAssets(bytes calldata params)
        external
        view
        returns (address[] memory)
    {
        return outAssets;
    }
}
