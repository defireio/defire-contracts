pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../common/IWETH.sol";
import "../../base/IOperation.sol";


contract Op_Unwrap_ETH is IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(
        uint256 amountWETH
    );

    address public ETH;
    address public WETH;

    constructor() public {
        ETH = address(0);
        WETH = address($(WETH));
    }

    /**
     * Fallback function accepts Ether transactions.
     */
    function() external payable {}

    /**
     * Execute the operation.
     * @param _inAmounts amounts of assets in.
     * @param _params params is the amount of WETH to unwrap
     */
    function operate(uint256[] calldata _inAmounts, bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        require(msg.value == 0, "This operation does not receive ethers");

        //In assets amounts
        require(_inAmounts.length != 0, "Need to set WETH amount");
        uint256 amountWETH = _inAmounts[0];

        //Get in assets
        if (amountWETH > 0) {
            IERC20(WETH).transferFrom(msg.sender, address(this), amountWETH);
        }

        //Get total balance of WETH, some may come from other operations
        uint256 finalAmountWETH = IERC20(WETH).balanceOf(address(this));

        //Transformed WETH received to ETH
        IWETH(WETH).withdraw(finalAmountWETH);
        require(
            IERC20(WETH).balanceOf(address(this)) == 0 &&
                address(this).balance == finalAmountWETH,
            "failed weth unwrap"
        );

        //Send out eth back
        Address.sendValue(msg.sender, finalAmountWETH);
        require(address(this).balance == 0, "ETH remainder");

        emit OperationExecuted(finalAmountWETH);

        //Returns out assets amounts
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = finalAmountWETH;
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
        _assets[0] = address(WETH);
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
