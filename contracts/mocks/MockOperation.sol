pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "../base/IOperation.sol";


/**
 * @title MockOperation
 * @dev Operation to make tests
 */
contract MockOperation is Initializable, IOperation {
    using SafeMath for uint256;

    event OperationExecuted(uint256[] inAmounts, uint256[] outAmounts);

    string name;
    uint8 times;
    uint8 divisor;
    address[] inAssets;
    address[] outAssets;

    function initialize(
        string memory _name,
        address[] memory _inAssets,
        address[] memory _outAssets,
        uint8 _times,
        uint8 _divisor
    ) public initializer payable {
        name = _name;
        times = _times;
        divisor = _divisor;
        inAssets = _inAssets;
        outAssets = _outAssets;
    }

    function() external payable {}

    //Operation
    function operate(uint256[] calldata _inAmounts, bytes calldata params)
        external
        payable
        returns (uint256[] memory)
    {
        require(_inAmounts.length > 0, "Must receive at least one amount");

        for (uint8 i = 0; i < inAssets.length; i++) {
            address _asset = inAssets[i];
            if (_asset != address(0)) {
                uint256 _amount = _inAmounts[i];
                IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
            }
        }
        uint256[] memory totals = new uint256[](outAssets.length);
        for (uint8 i = 0; i < outAssets.length; i++) {
            address _asset = outAssets[i];
            uint256 total;
            if (_asset != address(0)) {
                total = _inAmounts[0].mul(times).div(divisor);
                IERC20(_asset).transfer(msg.sender, total);
                emit OperationExecuted(_inAmounts, totals);
                totals[i] = total;
            } else {
                total = _inAmounts[0].mul(times).div(divisor);
                msg.sender.transfer(total);
                emit OperationExecuted(_inAmounts, totals);
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
