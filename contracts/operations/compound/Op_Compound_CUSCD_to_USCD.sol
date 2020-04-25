pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./ICToken.sol";
import "../../base/IOperation.sol";


contract Op_Compound_CUSDC_to_USDC is IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(uint256 amoundCUSDC, uint256 amountUSDC);

    address public USDC;
    address public cUSDC;

    constructor() public {
        USDC = address($(USDC));
        cUSDC = address($(CUSDC));
    }

    /**
     * Execute the operation.
     * @param _inAmounts amounts of assets in.
     * @param _params params is the amount to convert to CUSDC
     */
    function operate(uint256[] calldata _inAmounts, bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        require(msg.value == 0, "This operation does not receive ethers");

        //In assets amounts
        require(_inAmounts.length != 0, "Need to set CUSDC amount");
        uint256 amountCUSDC = _inAmounts[0];

        //Get in assets
        if (amountCUSDC > 0) {
            IERC20(cUSDC).transferFrom(msg.sender, address(this), amountCUSDC);
        }

        //Get total balance of CUSDC, some may come from other operations
        uint256 finalAmountCUSDC = IERC20(cUSDC).balanceOf(address(this));

        //Execute operation
        require(
            ICToken(cUSDC).redeem(finalAmountCUSDC) == 0,
            "operation failed"
        );
        require(IERC20(cUSDC).balanceOf(address(this)) == 0, "CUSDC remainder");

        //Send out assets back
        uint256 amountUSDC = IERC20(USDC).balanceOf(address(this));
        IERC20(USDC).transfer(msg.sender, amountUSDC);
        require(IERC20(USDC).balanceOf(address(this)) == 0, "USDC remainder");

        emit OperationExecuted(finalAmountCUSDC, amountUSDC);

        //Returns out assets amounts
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountUSDC;
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
        _assets[0] = address(cUSDC);
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
        _assets[0] = address(USDC);
        return _assets;
    }
}
