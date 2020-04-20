pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";

/**
 * @title FundToken
 * @dev ERC20 token that represent the share of the funds.
 */
contract FundToken is Initializable, ERC20Mintable, ERC20Burnable {
    /**
     * Initialize the contract.
     * @param _fund fund that is owner of the token.
     */
    function initialize(address _fund) public initializer {
        ERC20Mintable.initialize(_fund);
    }

    /**
     * Returns true of the token belons to that fund.
     * @param _fund fund to check.
     */
    function isFund(address _fund) public view returns (bool) {
        return isMinter(_fund);
    }
}
