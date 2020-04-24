pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./IUniswap.sol";
import "../../base/IOperation.sol";


contract Op_Uniswap_ETH_to_DAI is Initializable, IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(
        uint256 amountETH,
        uint256 minDAI,
        uint256 deadline,
        uint256 amountDAI
    );

    address payable public UNISWAP;
    address public DAI;

    function initialize() public initializer {
        UNISWAP = address($(UNISWAP));
        DAI = address($(DAI));
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
     * @param _params params is the amount of ETH to swap to DAI, the min amount of DAI to get and the deadline
     */
    function operate(uint256[] calldata _inAmounts, bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        //In assets amounts
        require(_inAmounts.length != 0, "Need to set ETH amount");
        uint256 amountETH = _inAmounts[0];

        //Get params
        uint256 minDAI;
        uint256 deadline;
        (minDAI, deadline) = getParams(_params);

        //Get in assets
        require(
            msg.value == amountETH,
            "Incorrect amount of ethers sent to the operation"
        );

        //Get total balance of ETH, some may come from other operations
        uint256 finalAmountETH = address(this).balance;

        //Execute operation
        require(
            IUniswap(UNISWAP).ethToTokenSwapInput.value(finalAmountETH)(
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

        emit OperationExecuted(finalAmountETH, minDAI, deadline, amountDAI);

        //Returns out assets amounts
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountDAI;
        return amounts;
    }

    /**
     * Returns the assets that the operation receives. 0x0 address for ETH
     * @param _params params of the operation.
     */
    function getInAssets(bytes calldata _params)
        external
        view
        returns (address[] memory)
    {
        address[] memory _assets = new address[](1);
        _assets[0] = address(0);
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
