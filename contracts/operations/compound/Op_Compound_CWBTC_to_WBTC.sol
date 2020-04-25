pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./ICToken.sol";
import "../../base/IOperation.sol";


contract Op_Compound_CWBTC_to_WBTC is IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(uint256 amoundCWBTC, uint256 amountWBTC);

    address public WBTC;
    address public cWBTC;

    constructor() public {
        WBTC = address($(WBTC));
        cWBTC = address($(CWBTC));
    }

    /**
     * Execute the operation.
     * @param _inAmounts amounts of assets in.
     * @param _params params is the amount to convert to CWBTC
     */
    function operate(uint256[] calldata _inAmounts, bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        require(msg.value == 0, "This operation does not receive ethers");

        //In assets amounts
        require(_inAmounts.length != 0, "Need to set CWBTC amount");
        uint256 amountCWBTC = _inAmounts[0];

        //Get in assets
        if (amountCWBTC > 0) {
            IERC20(cWBTC).transferFrom(msg.sender, address(this), amountCWBTC);
        }

        //Get total balance of CWBTC, some may come from other operations
        uint256 finalAmountCWBTC = IERC20(cWBTC).balanceOf(address(this));

        //Execute operation
        require(
            ICToken(cWBTC).redeem(finalAmountCWBTC) == 0,
            "operation failed"
        );
        require(IERC20(cWBTC).balanceOf(address(this)) == 0, "CWBTC remainder");

        //Send out assets back
        uint256 amountWBTC = IERC20(WBTC).balanceOf(address(this));
        IERC20(WBTC).transfer(msg.sender, amountWBTC);
        require(IERC20(WBTC).balanceOf(address(this)) == 0, "WBTC remainder");

        emit OperationExecuted(finalAmountCWBTC, amountWBTC);

        //Returns out assets amounts
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountWBTC;
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
        _assets[0] = address(cWBTC);
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
        _assets[0] = address(WBTC);
        return _assets;
    }
}
