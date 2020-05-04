pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./IUniswap.sol";
import "../../base/IOperation.sol";


contract Op_Uniswap_ETH_to_ERC20 is IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(
        uint256 amountETH,
        uint256 minOutAsset,
        uint256 deadline,
        uint256 amountOutAsset
    );

    address public outAsset;
    address public exchange;
    address public ETH;

    constructor(address _outAsset, address _exchange) public {
        outAsset = _outAsset;
        exchange = _exchange;
        ETH = address(0);
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
        returns (uint256 minOutAsset, uint256 deadline)
    {
        (minOutAsset, deadline) = abi.decode(_params, (uint256, uint256));
    }

    /**
     * Execute the operation.
     * @param _params params is the amount of ETH to swap to out asset, the min amount of out asset to get and the deadline
     */
    function operate(bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        //Get params
        uint256 minOutAsset;
        uint256 deadline;
        (minOutAsset, deadline) = getParams(_params);

        //Get total balance of ETH, some may come from other operations
        uint256 finalAmountETH = address(this).balance;

        //Execute operation
        require(
            IUniswap(exchange).ethToTokenSwapInput.value(finalAmountETH)(
                minOutAsset,
                deadline
            ) > 0,
            "operation failed"
        );
        require(address(this).balance == 0, "eth remainder");

        //Send out assets back
        uint256 amountOutAsset = IERC20(outAsset).balanceOf(address(this));
        IERC20(outAsset).transfer(msg.sender, amountOutAsset);
        require(IERC20(outAsset).balanceOf(address(this)) == 0, "Out asset remainder");

        emit OperationExecuted(finalAmountETH, minOutAsset, deadline, amountOutAsset);

        //Returns out assets amounts
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountOutAsset;
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
        _assets[0] = ETH;
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
