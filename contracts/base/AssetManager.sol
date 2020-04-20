pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../registry/FundRegistry.sol";
import "../registry/AssetRegistry.sol";


/**
 * @title AssetManager
 * @dev Manages a set of assets.
 */
contract AssetManager is Initializable, Context {
    bool assetsWhitelist;
    address[] assets;
    mapping(address => bool) assetWhitelisted;
    FundRegistry fundRegistry;
    AssetRegistry assetRegistry;

    /**
     * Initialize the contract.
     * @param _assets whitelisted assets list.
     * @param _fundRegistry registry contracts address of funds.
     * @param _assetRegistry registry contract address of assets.
     */
    function initialize(
        address[] memory _assets,
        FundRegistry _fundRegistry,
        AssetRegistry _assetRegistry
    ) public initializer {
        assets = _assets;
        assetsWhitelist = _assets.length > 0;
        for (uint256 i = 0; i < _assets.length; i++) {
            assetWhitelisted[_assets[i]] = true;
        }
        fundRegistry = _fundRegistry;
        assetRegistry = _assetRegistry;
    }

    /**
     * Returns the total amount of assets.
     */
    function getTotalAssets() public view returns (uint256) {
        return getAssets().length;
    }

    /**
     * Returns an array of all the assets it contains.
     */
    function getAssets() public view returns (address[] memory) {
        address[] memory assetsWithBalance;
        uint256 index = 0;
        if (assetsWhitelist) {
            assetsWithBalance = new address[](assets.length);
            for (uint256 i = 0; i < assets.length; i++) {
                if (hasAsset(assets[i])) {
                    assetsWithBalance[index] = assets[i];
                    index++;
                }
            }
        } else {
            uint256 total = assetRegistry.getTotalElements();
            assetsWithBalance = new address[](total);
            for (uint256 i = 0; i < total; i++) {
                address asset = assetRegistry.getElementAtIndex(i);
                if (hasAsset(asset)) {
                    assetsWithBalance[index] = asset;
                    index++;
                }
            }
        }
        address[] memory result = new address[](index);
        for (uint256 j = 0; j < index; j++) {
            result[j] = assetsWithBalance[j];
        }
        return result;
    }

    /**
     * Returns true if it contains the asset.
     * @param _asset asset to check.
     */
    function isAsset(address _asset) public view returns (bool) {
        if (assetsWhitelist) {
            return assetWhitelisted[_asset];
        } else if (
            (!assetRegistry.isElement(_asset)) &&
            (!fundRegistry.isFundToken(_asset))
        ) {
            return false;
        }
        return true;
    }

    /**
     * Returns true if it the asset has balance > 0.
     * @param _asset asset to check.
     */
    function hasAsset(address _asset) public view returns (bool) {
        if (_asset == address(0)) {
            return address(this).balance > 0;
        } else {
            return IERC20(_asset).balanceOf(address(this)) > 0;
        }
    }

    /**
     * Returns the index of an asset.
     * If not found, returns array length.
     * @param _asset asset to get index.
     */
    function getAssetIndex(address _asset) internal view returns (uint256) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == _asset) {
                return i;
            }
        }
        return assets.length;
    }
}
