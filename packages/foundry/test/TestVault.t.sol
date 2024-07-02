// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../contracts/TestToken.sol";
import "../contracts/TestVault.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";


contract TestVaultTest is Test {
    using Math for uint256;

	TestToken public testToken;
    TestVault public testVault;	

    address public admin;
	address[] public users;
    address public feeRecipient;

    uint256[] amounts = [100 * 1e18, 200 * 1e18, 150 * 1e18, 250 * 1e18, 300 * 1e18];

    function setUp() public {
    	admin = address(this);
        feeRecipient = address(0x123);

        for (uint256 i = 1; i <= 5; i++) {
            address user = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
            users.push(user);
        }

    	testToken = new TestToken();
    	testVault = new TestVault(IERC20(testToken), 100 * 1e18, 8000 * 1e18, feeRecipient);

        for(uint256 i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            testToken.faucet();
            vm.stopPrank();
            testVault.addWhitelisted(users[i]);
        }

        for (uint256 i = 0; i < users.length; i++) {
            uint256 amount = amounts[i];

            vm.startPrank(users[i]);
            testToken.approve(address(testVault), amount);
            testVault.deposit(amount, users[i]);
            vm.stopPrank();
        }

        // Add yield
        vm.startPrank(admin);
        testToken.faucet();
        testToken.transfer(address(testVault), 120 * 1e18);
        vm.stopPrank();
    }

    function testUserSharesAndAssets() public view {
        uint256 totalFee = 0;

        for (uint256 i = 0; i < users.length; i++) {
            uint256 fee = _feeFromTotal(amounts[i]);
            uint256 amount = amounts[i] - fee;
            totalFee = totalFee + fee;

            //1. check shares;
            //Initially, the deposit amount and the shares amount are always the same when _decimalsOffset() is 0.
            assertEq(testVault.balanceOf(users[i]), amount);

            //Calculate assets from shares
            uint256 siRedeemAssets = amount.mulDiv(testVault.totalAssets(), testVault.totalSupply(), Math.Rounding.Floor);
            //2. check _convertToAssets is working correctly
            assertApproxEqAbs(testVault.previewRedeem(testVault.balanceOf(users[i])), siRedeemAssets, 1);
        }

        //3. check fee accumulated
        assertEq(testToken.balanceOf(feeRecipient), totalFee);
    }

    function testRevertErrors() public {
        uint256 depositAssets = 50 * 1e18;
        vm.startPrank(users[1]);
        vm.expectRevert(abi.encodeWithSelector(
                TestVault.TestVaultDepositBelowThreshold.selector, 
                users[1], 
                depositAssets, 
                testVault.minDepositAmount()
        ));
        testVault.deposit(depositAssets, users[1]);
        vm.stopPrank();

        depositAssets = 7200 * 1e18;

        vm.startPrank(users[1]);
        vm.expectRevert(abi.encodeWithSelector(
                TestVault.TestVaultExceededMaxTotalAmount.selector, 
                users[1], 
                depositAssets - _feeFromTotal(depositAssets),
                testVault.totalAssets(), 
                8000 * 1e18
        ));
        testVault.deposit(depositAssets, users[1]);
        vm.stopPrank();
    }

    function testWithdrawRedeem() public {
        // 1 - users[1] - Withdraw
        uint256 userShares = testVault.balanceOf(users[1]);
        uint256 userAssets = testVault.previewRedeem(userShares);
        uint256 prevUserAssetBalance = testToken.balanceOf(users[1]);

        vm.startPrank(users[1]);
        testVault.withdraw(userAssets, users[1], users[1]);
        vm.stopPrank();

        // 1-1: Check if users[1] asset balance is updated correctly
        assertEq(testToken.balanceOf(users[1]), prevUserAssetBalance + userAssets);

        // 1-2: Check if users[1] share is burnt correctly
        assertEq(testVault.balanceOf(users[1]), 0);

        //add yield
        _addYield(229 * 1e18);

        // 2 - users2[2] - Redeem
        userShares = testVault.balanceOf(users[2]);
        prevUserAssetBalance = testToken.balanceOf(users[2]);

        vm.startPrank(users[2]);
        testVault.redeem(userShares, users[2], users[2]);
        vm.stopPrank();

        // 2-1: Check if users[2] share is burnt correctly
        assertEq(testVault.balanceOf(users[2]), 0);

        userAssets = testToken.balanceOf(users[2]) - prevUserAssetBalance;

        // 2-2: Check if users[2] asset balance is updated correctly
        assertEq(testVault.previewWithdraw(userAssets), userShares);
    }

    function testMintDeposit() public {

        // 1 - users[1]
        uint256 targetShare = 100 * 1e18;
        uint256 prevShares = testVault.balanceOf(users[1]);
        uint256 prevVaultAssets = testToken.balanceOf(address(testVault));
        uint256 totalFee = testToken.balanceOf(feeRecipient);
        uint256 calculatedAssets = testVault.previewMint(targetShare);
        uint256 depositFee = _feeFromTotal(calculatedAssets);

        vm.startPrank(users[1]);
        testToken.approve(address(testVault), calculatedAssets);
        testVault.deposit(calculatedAssets, users[1]);
        vm.stopPrank();

        // 1-1: Check if the shares value of users[1] is updated correctly.
        assertEq(testVault.balanceOf(users[1]), prevShares + targetShare);

        // 1-2: Check if the assets have been accurately transferred to the vault.
        assertEq(testToken.balanceOf(address(testVault)), prevVaultAssets + calculatedAssets - depositFee);

        // 1-3: Check if the fees have been accurately accumulated.
        assertEq(testToken.balanceOf(feeRecipient), totalFee + depositFee);

        //add yield
        _addYield(472 * 1e18);

        //2 - user[3]
        targetShare = 150 * 1e18;
        prevShares = testVault.balanceOf(users[3]);
        prevVaultAssets = testToken.balanceOf(address(testVault));
        calculatedAssets = testVault.previewMint(targetShare);
        depositFee = _feeFromTotal(calculatedAssets);
        totalFee = testToken.balanceOf(feeRecipient);

        vm.startPrank(users[3]);
        testToken.approve(address(testVault), calculatedAssets);
        testVault.mint(targetShare, users[3]);
        vm.stopPrank();

        // 2-1: Check if the shares value of users[3] is updated correctly.
        assertEq(testVault.balanceOf(users[3]), targetShare + prevShares);
        // 2-2: Check if the assets have been accurately transferred to the vault.
        assertEq(testToken.balanceOf(address(testVault)), prevVaultAssets + calculatedAssets - depositFee);
        // 2-3: Check if the fees have been accurately accumulated.
        assertEq(testToken.balanceOf(feeRecipient), totalFee + depositFee);

        //add yield
        _addYield(217 * 1e18);

        //3 - user[4]
        uint256 depositAssets = 188 * 1e18;
        uint256 calculatedShares = testVault.previewDeposit(depositAssets);
        prevShares = testVault.balanceOf(users[4]);
        prevVaultAssets = testToken.balanceOf(address(testVault));
        depositFee = _feeFromTotal(depositAssets);
        totalFee = testToken.balanceOf(feeRecipient);

        vm.startPrank(users[4]);
        testToken.approve(address(testVault), depositAssets);
        testVault.deposit(depositAssets, users[4]);
        vm.stopPrank();

        // 3-1: Check if the shares value of users[4] is updated correctly.
        assertEq(testVault.balanceOf(users[4]), calculatedShares + prevShares);
        // 3-2: Check if the assets have been accurately transferred to the vault.
        assertEq(testToken.balanceOf(address(testVault)), prevVaultAssets + depositAssets - depositFee);
        // 3-3: Check if the fees have been accurately accumulated.
        assertEq(testToken.balanceOf(feeRecipient), totalFee + depositFee);
    }

    function _addYield(uint256 yieldAmount) private {
        vm.startPrank(admin);
        testToken.transfer(address(testVault), yieldAmount);
        vm.stopPrank();
    }

    function _feeFromTotal(uint256 assets) private view returns (uint256) {
        return assets.mulDiv(testVault.FEE_PERCENT(), 100, Math.Rounding.Ceil);
    }
}