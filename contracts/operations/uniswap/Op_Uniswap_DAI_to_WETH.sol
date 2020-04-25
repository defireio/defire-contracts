pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./IUniswap.sol";
import "../common/IWETH.sol";
import "../../base/IOperation.sol";


contract Op_Uniswap_DAI_to_WETH is IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(
        uint256 amountDAI,
        uint256 minEth,
        uint256 deadline,
        uint256 amountWETH
    );

    address public UNISWAP;
    address public DAI;
    address public WETH;

    constructor() public {
        UNISWAP = address($(UNISWAP));
        DAI = address($(DAI));
        WETH = address($(WETH));
        approveToken();
    }

    /**
     * Fallback function accepts Ether transactions.
     */
    function() external payable {}

    function approveToken() private {
        IERC20(DAI).approve(UNISWAP, uint256(-1));
    }

    /**
     * Decode the params of the operation.
     * @param _params params of the operation.
     */
    function getParams(bytes memory _params)
        public
        pure
        returns (uint256 minEth, uint256 deadline)
    {
        (minEth, deadline) = abi.decode(_params, (uint256, uint256));
    }

    /**
     * Execute the operation.
     * @param _inAmounts amounts of assets in.
     * @param _params params is the amount of DAI to swap to WETH, the min amount of WETH to get and the deadline
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

        //Get params
        uint256 minEth;
        uint256 deadline;
        (minEth, deadline) = getParams(_params);

        //Get in assets
        if (amountDAI > 0) {
            IERC20(DAI).transferFrom(msg.sender, address(this), amountDAI);
        }

        //Get total balance of DAI, some may come from other operations
        uint256 finalAmountDAI = IERC20(DAI).balanceOf(address(this));

        //Execute operation
        require(
            IUniswap(UNISWAP).tokenToEthSwapInput(
                finalAmountDAI,
                minEth,
                deadline
            ) > 0,
            "operation failed"
        );
        require(IERC20(DAI).balanceOf(address(this)) == 0, "dai remainder");

        //Transformed ETH received to WETH
        uint256 ethBalance = address(this).balance;
        IWETH(WETH).deposit.value(ethBalance)();
        require(
            IERC20(WETH).balanceOf(address(this)) == ethBalance &&
                address(this).balance == 0,
            "failed weth unwrap"
        );

        //Send out assets back
        uint256 amountWETH = IERC20(WETH).balanceOf(address(this));
        IERC20(WETH).transfer(msg.sender, amountWETH);
        require(IERC20(WETH).balanceOf(address(this)) == 0, "WETH remainder");

        emit OperationExecuted(finalAmountDAI, minEth, deadline, amountWETH);

        //Returns out assets amounts
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountWETH;
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
        _assets[0] = address(WETH);
        return _assets;
    }
}
