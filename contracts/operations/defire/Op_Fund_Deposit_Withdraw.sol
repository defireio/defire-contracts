pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./IDefireFund.sol";
import "../../base/IOperation.sol";


contract Op_Fund_Deposit_Withdraw is IOperation {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event OperationExecuted(bool isDeposit);

    constructor() public {}

    /**
     * Execute the withdraw or deposit operation.
     * @param _params params of the operation.
     */
    function operate(bytes calldata _params)
        external
        payable
        returns (uint256[] memory)
    {
        address fundAddress;
        bool isDeposit;
        (fundAddress, isDeposit) = getOperationBasicData(_params);
        address fundToken = IDefireFund(fundAddress).getFundToken();
        uint256[] memory outAmounts;
        if (isDeposit) {
            //Check params
            address[] memory assets;
            uint256[] memory amounts;
            (assets, amounts) = getAssetsDataToDeposit(_params);
            require(
                assets.length == amounts.length,
                "Number of amounts does not match number of assets"
            );

            //Aprove tokens
            uint256 ethersAmount = 0;
            for (uint8 i = 0; i < assets.length; i++) {
                if (assets[i] == address(0)) {
                    ethersAmount = amounts[i];
                } else {
                    IERC20(assets[i]).approve(fundAddress, amounts[i]);
                }
            }

            //Execute deposit
            if (ethersAmount > 0) {
                IDefireFund(fundAddress).deposit.value(ethersAmount)(
                    assets,
                    amounts
                );
            } else {
                IDefireFund(fundAddress).deposit(assets, amounts);
            }

            //Send out assets back
            outAmounts = new uint256[](1);
            outAmounts[0] = IERC20(fundToken).balanceOf(address(this));
            IERC20(fundToken).transfer(msg.sender, outAmounts[0]);

            emit OperationExecuted(true);
        } else {
            //Geth fund assets before withdaw
            address[] memory assets = IDefireFund(fundAddress).getAssets();

            //Aprove token
            uint256 amount = getInAmmountToWithdraw(_params);
            IERC20(fundToken).approve(fundAddress, amount);

            //Execute withdraw
            IDefireFund(fundAddress).withdraw(amount);

            //Send out assets back
            outAmounts = new uint256[](assets.length);
            for (uint8 i = 0; i < assets.length; i++) {
                if (assets[i] == address(0)) {
                    outAmounts[i] = address(this).balance;
                    Address.sendValue(msg.sender, outAmounts[i]);
                } else {
                    outAmounts[i] = IERC20(assets[i]).balanceOf(address(this));
                    IERC20(assets[i]).transfer(msg.sender, outAmounts[i]);
                }
            }

            emit OperationExecuted(false);
        }
        return outAmounts;
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
        address fundAddress;
        bool isDeposit;
        (fundAddress, isDeposit) = getOperationBasicData(_params);
        if (isDeposit) {
            if (IDefireFund(fundAddress).getTotalAssets() == 0) {
                address[] memory assets;
                (assets, ) = getAssetsDataToDeposit(_params);
                return assets;
            } else {
                return IDefireFund(fundAddress).getAssets();
            }
        } else {
            //Returns fund token
            address[] memory assets;
            assets = new address[](1);
            assets[0] = address(IDefireFund(fundAddress).getFundToken());
            return assets;
        }
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
        address fundAddress;
        bool isDeposit;
        (fundAddress, isDeposit) = getOperationBasicData(_params);
        if (isDeposit) {
            //Returns fund token
            address[] memory assets;
            assets = new address[](1);
            assets[0] = address(IDefireFund(fundAddress).getFundToken());
            return assets;
        } else {
            if (IDefireFund(fundAddress).getTotalAssets() == 0) {
                address[] memory empty;
                return empty;
            } else {
                return IDefireFund(fundAddress).getAssets();
            }
        }
    }

    /**
     * Returns true if operation is deposit.
     * @param _params params of the operation.
     */
    function getOperationBasicData(bytes memory _params)
        public
        pure
        returns (address, bool)
    {
        return abi.decode(_params, (address, bool));
    }

    /**
     * Returns the assets to deposit.
     * @param _params params of the operation.
     */
    function getAssetsDataToDeposit(bytes memory _params)
        public
        pure
        returns (address[] memory assets, uint256[] memory inAmounts)
    {
        (, , assets, inAmounts) = abi.decode(
            _params,
            (address, bool, address[], uint256[])
        );
    }

    /**
     * Returns the amount of the assets to deposit.
     * @param _params params of the operation.
     */
    function getInAmmountToWithdraw(bytes memory _params)
        public
        pure
        returns (uint256 inAmount)
    {
        (, , inAmount) = abi.decode(_params, (address, bool, uint256));
    }
}
