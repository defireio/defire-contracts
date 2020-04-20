pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./IUniswap.sol";
import "../common/IWETH.sol";
import "../../base/IOperation.sol";


contract Op_Uniswap_WETH_to_DAI is Initializable, IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(
        uint256 amountWETH,
        uint256 minDAI,
        uint256 deadline,
        uint256 amountDAI
    );

    address payable public UNISWAP;
    address public DAI;
    address public WETH;

    function initialize() public initializer {
        UNISWAP = address($(UNISWAP));
        DAI = address($(DAI));
        WETH = address($(WETH));
    }

    /**
     * Fallback function accepts Ether transactions.
     */
    function() external payable {}

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
     * @param _params params is the amount of WETH to swap to DAI, the min amount of DAI to get and the deadline
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

        //Get params
        uint256 minDAI;
        uint256 deadline;
        (minDAI, deadline) = getParams(_params);

        //Get in assets
        if (amountWETH > 0) {
            IERC20(WETH).transferFrom(msg.sender, address(this), amountWETH);
        }

        //Transformed WETH received to ETH
        IWETH(WETH).withdraw(amountWETH);
        require(
            IERC20(WETH).balanceOf(address(this)) == 0 &&
                address(this).balance == amountWETH,
            "failed weth unwrap"
        );

        //Execute operation
        require(
            IUniswap(UNISWAP).ethToTokenSwapInput.value(amountWETH)(
                minDAI,
                deadline
            ) > 0,
            "operation failed"
        );
        require(address(this).balance == 0, "eth remainder");

        //Send out assets back
        uint256 amountDAI = IERC20(DAI).balanceOf(address(this));
        IERC20(DAI).transfer(msg.sender, amountDAI);
        require(IERC20(DAI).balanceOf(address(this)) == 0, "DAI remainder");

        emit OperationExecuted(amountWETH, minDAI, deadline, amountDAI);

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
        _assets[0] = address(DAI);
        return _assets;
    }
}
