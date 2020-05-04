pragma solidity ^0.5.0;


/**
 * @title DefireFund
 * @dev DefireFund is a contract that represents a fund for DeFi assets,
 * allowing fund managers to operate those assets.
 */
contract IDefireFund {
    /**
     * Deposit ERC20 tokens in the fund.
     * It has to deposit same proportonial amounts for each token of the fund.
     * It mints and send the fund token to the sender.
     * @param _assets assets to deposit.
     * @param _amounts amounts of assets to deposit.
     */
    function deposit(address[] memory _assets, uint256[] memory _amounts)
        public
        payable;

    /**
     * Withdraw ERC20 tokens from the fund.
     * It withdraws each token of the fund in proportonial amounts to the fund token amount received.
     * It receives and burns the fund token.
     * @param _amount amount of fund token to deposit.
     */
    function withdraw(uint256 _amount) public;

    /**
     * Returns the total amount of assets.
     */
    function getTotalAssets() public view returns (uint256);

    /**
     * Returns an array of all the assets it contains.
     */
    function getAssets() public view returns (address[] memory);

    /**
     * Returns the token of the fund
     */
    function getFundToken() public view returns (address);
}
