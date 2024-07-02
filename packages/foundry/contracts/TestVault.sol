//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract TestVault is ERC4626, AccessControl {
	using Math for uint256;

	uint256 public  minDepositAmount;
    uint256 public maxTotalAmount;
    uint256 public constant FEE_PERCENT = 1;
    address public feeRecipient;

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

    error TestVaultDepositBelowThreshold(address sender, uint256 depositAmount, uint256 threshold);
    error TestVaultExceededMaxTotalAmount(address sender, uint256 depositAmount, uint256 beforeBalance, uint256 threshold);
    error TestVaultAssetAddressIsZero();
    error TestVaultFeeRecipientIsZero();
    error TestVaultFeeRecipientIsVault();
    error TestVaultMinDepositAmountValidError();
    error TestVaultMaxTotalAmountValidError();
    error TestVaultNotWhiteList(address owner);

	constructor(
        IERC20 asset_,
        uint256 minDepositAmount_,
        uint256 maxTotalAmount_,
        address feeRecipient_
    ) ERC20("Test Vault Shares", "TVS") ERC4626(asset_) {
    	if(address(asset_) == address(0))
    		revert TestVaultAssetAddressIsZero();
    	if(feeRecipient_ == address(0))
    		revert TestVaultFeeRecipientIsZero();
    	if(minDepositAmount_ == 0)
    		revert TestVaultMinDepositAmountValidError();
    	if(maxTotalAmount_ == 0)
    		revert TestVaultMaxTotalAmountValidError();

		minDepositAmount = minDepositAmount_;
        maxTotalAmount = maxTotalAmount_;
        feeRecipient = feeRecipient_;
        
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }


    function setFeeRecipient(address feeRecipient_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    	if(feeRecipient_ == address(0))
    		revert TestVaultFeeRecipientIsZero();
   		if(feeRecipient_ == address(this))
   			revert TestVaultFeeRecipientIsVault();

        feeRecipient = feeRecipient_;
    }

    function addWhitelisted(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(WHITELISTED_ROLE, account);
    }

    function removeWhitelisted(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(WHITELISTED_ROLE, account);
    }

    function previewDeposit(uint256 assets) public view override returns (uint256) {
    	uint256 fee = _feeFromTotal(assets);
    	return super.previewDeposit(assets - fee);
    }

    function previewMint(uint256 shares) public view override returns (uint256) {
   		uint256 assets = super.previewMint(shares);
   		return assets + _feeFromRaw(assets);
    }

    function deposit(uint256 assets, address receiver) public override onlyRole(WHITELISTED_ROLE) returns (uint256) {
   		if(assets < minDepositAmount)
   			revert TestVaultDepositBelowThreshold(_msgSender(), assets, minDepositAmount);

   		uint256 fee = _feeFromTotal(assets);
   		uint256 excludedFeeAssets = assets - fee;

   		uint256 currentTotalAssets = totalAssets();
   		if(currentTotalAssets + excludedFeeAssets > maxTotalAmount) {
			revert TestVaultExceededMaxTotalAmount(_msgSender(), excludedFeeAssets, currentTotalAssets, maxTotalAmount);
   		}

   		// don't use this.previewDeposit to save gas fees, instead, use super.previewDeposit
   		uint256 shares = super.previewDeposit(excludedFeeAssets);

   		_deposit(_msgSender(), receiver, assets, shares);

   		if (fee > 0) {
            SafeERC20.safeTransfer(IERC20(asset()), feeRecipient, fee);
        }

   		return shares;
    }

	function mint(uint256 shares, address receiver) public override onlyRole(WHITELISTED_ROLE) returns (uint256) {
		// don't use this.previewMint to save gas fees, instead, use super.previewMint
		uint256 excludedFeeAssets = super.previewMint(shares);

		uint256 currentTotalAssets = totalAssets();
		if(currentTotalAssets + excludedFeeAssets > maxTotalAmount) {
			revert TestVaultExceededMaxTotalAmount(_msgSender(), excludedFeeAssets, currentTotalAssets, maxTotalAmount);
   		}

		uint256 fee = _feeFromRaw(excludedFeeAssets);
		uint256 assets = excludedFeeAssets + fee;
		
		if(assets < minDepositAmount)
   			revert TestVaultDepositBelowThreshold(_msgSender(), assets, minDepositAmount);

		_deposit(_msgSender(), receiver, assets, shares);

		if (fee > 0) {
            SafeERC20.safeTransfer(IERC20(asset()), feeRecipient, fee);
        }

		return assets;
	}

	function withdraw(uint256 assets, address receiver, address owner) public override onlyRole(WHITELISTED_ROLE) returns (uint256) {
		if(!hasRole(WHITELISTED_ROLE, owner))
			revert TestVaultNotWhiteList(owner);

		return super.withdraw(assets, receiver, owner);
	}

	function redeem(uint256 shares, address receiver, address owner) public override onlyRole(WHITELISTED_ROLE) returns (uint256) {
		if(!hasRole(WHITELISTED_ROLE, owner))
			revert TestVaultNotWhiteList(owner);

		return super.redeem(shares, receiver, owner);
	}

	function _feeFromTotal(uint256 assets) private pure returns (uint256) {
        return assets.mulDiv(FEE_PERCENT, 100, Math.Rounding.Ceil);
    }

    function _feeFromRaw(uint256 assets) private pure returns (uint256) {
        return assets.mulDiv(FEE_PERCENT, 100 - FEE_PERCENT, Math.Rounding.Ceil);
    }
}