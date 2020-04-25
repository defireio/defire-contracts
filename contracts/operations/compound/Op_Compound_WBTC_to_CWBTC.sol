pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./ICToken.sol";
import "../../base/IOperation.sol";


contract Op_Compound_WBTC_to_CWBTC is IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(uint256 amoundWBTC, uint256 amountCWBTC);

    address public WBTC;
    address public cWBTC;

    constructor() public {
        WBTC = address($(WBTC));
        cWBTC = address($(CWBTC));
        approveToken();
    }

    function approveToken() private {
        IERC20(WBTC).approve(cWBTC, uint256(-1));
    }

    /**
     * Execute the operation.
     * @param _inAmounts amounts of assets in.
     * @param _params params is the amount of WBTC to convert to CWBTC
     */
    function operate(uint256[] calldata _inAmounts, bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        require(msg.value == 0, "This operation does not receive ethers");

        //In assets amounts
        require(_inAmounts.length != 0, "Need to set WBTC amount");
        uint256 amountWBTC = _inAmounts[0];

        //Get in assets
        if (amountWBTC > 0) {
            IERC20(WBTC).transferFrom(msg.sender, address(this), amountWBTC);
        }

        //Get total balance of WBTC, some may come from other operations
        uint256 finalAmountWBTC = IERC20(WBTC).balanceOf(address(this));

        //Execute operation
        require(ICToken(cWBTC).mint(finalAmountWBTC) == 0, "operation failed");
        require(IERC20(WBTC).balanceOf(address(this)) == 0, "WBTC remainder");

        //Send out assets back
        uint256 amountCWBTC = IERC20(cWBTC).balanceOf(address(this));
        IERC20(cWBTC).transfer(msg.sender, amountCWBTC);
        require(IERC20(cWBTC).balanceOf(address(this)) == 0, "CWBTC remainder");

        emit OperationExecuted(finalAmountWBTC, amountCWBTC);

        //Returns out assets amounts
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountCWBTC;
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
        _assets[0] = address(WBTC);
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
        _assets[0] = address(cWBTC);
        return _assets;
    }
}
