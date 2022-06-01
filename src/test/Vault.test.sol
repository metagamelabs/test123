// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import { BaseTest, console } from "./base/BaseTest.t.sol";
import {CardToken} from "../main/CardToken.sol";
import {Vault} from "../main/Vault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultTest is BaseTest {

    CardToken cardToken;
    Vault vault;
	function setUp() public {
        cardToken = new CardToken();
        vault = new Vault(address(cardToken));
    }

	function testStakeAndUnstakeCARD() public {
        address userAddr = address(accounts.PUBLIC_KEYS(0));
		console.log("user addr:", userAddr);

        // assert starting balance of user and vault is 0
        assertEq(cardToken.balanceOf(userAddr),0);
        assertEq(cardToken.balanceOf(address(vault)), 0);

        // mint 10 CARD tokens to user
        cardToken.mint(userAddr, 10);
        assertEq(cardToken.balanceOf(userAddr),10);

        // approve vault to spend userAddr tokens
        vm.prank(userAddr);
        cardToken.approve(address(vault), 100000);

        // stake 9 CARD tokens as user
        vm.prank(userAddr);
        vault.stake(9);
        assertEq(cardToken.balanceOf(userAddr), 1);
        assertEq(cardToken.balanceOf(address(vault)), 9);

        // unstake tokens (twice, from original staker and another addr)
        vm.prank(userAddr);
        vault.unstake(userAddr, 5);

        // This will be run using some other address (prank wears off)
        vault.unstake(userAddr, 4);
        assertEq(cardToken.balanceOf(userAddr), 10);
        assertEq(cardToken.balanceOf(address(vault)), 0);
	}

    function testStakeUnstakeMoreThanBalanceReverts() public {
        address userAddr = address(accounts.PUBLIC_KEYS(0));

        // assert starting balance is 0
        assertEq(cardToken.balanceOf(userAddr),0);

        // mint 10 CARD tokens to user
        cardToken.mint(userAddr, 10);
        assertEq(cardToken.balanceOf(userAddr),10);

        // approve vault to spend userAddr tokens
        vm.prank(userAddr);
        cardToken.approve(address(vault), 100000);

        // try to stake 11 CARD
        vm.prank(userAddr);
        vm.expectRevert(ERC20_INVALID_BALANCE);
        vault.stake(11);

        // stake 10 CARD, so that we can try and unstake more than amount staked
        vm.prank(userAddr);
        vault.stake(10);
        bytes memory expectedError = "requires input _amount <= user.stakedAmount";
        vm.expectRevert(expectedError);
        vault.unstake(userAddr, 11);
    }

    function testUnstakeNonUserReverts() public {
        address userAddr = address(accounts.PUBLIC_KEYS(0));
        bytes memory expectedError = "no staked balance to unstake";
        vm.expectRevert(expectedError);
        vault.unstake(userAddr, 10);
    }

    function testLockingAndImmediateClaim() public {
        address userAddr = address(accounts.PUBLIC_KEYS(0));

        // mint 10 CARD tokens to user
        cardToken.mint(userAddr, 10);
        assertEq(cardToken.balanceOf(userAddr),10);

        // approve vault to spend userAddr tokens
        vm.prank(userAddr);
        cardToken.approve(address(vault), 100000);

        // lock 10 tokens
        vm.prank(userAddr);
        vault.lock(10);

        // assert user balance is 0, and vault is 10
        assertEq(cardToken.balanceOf(userAddr),0);
        assertEq(cardToken.balanceOf(address(vault)), 10);


        // try claiming immediately, expect 0 claimed.
        vm.prank(userAddr);
        vault.claimUnlockedTokens();
        assertEq(cardToken.balanceOf(userAddr),0);
        assertEq(cardToken.balanceOf(address(vault)), 10);

        // try claiming after 29 days, expect 0 claimed.
        vm.prank(userAddr);
        vm.warp(block.timestamp + 29 days);
        vault.claimUnlockedTokens();
        assertEq(cardToken.balanceOf(userAddr),0);
        assertEq(cardToken.balanceOf(address(vault)), 10);
    }

    function testLockingAndClaimAfterFullUnlock() public {
        address userAddr = address(accounts.PUBLIC_KEYS(0));

        // mint 10 CARD tokens to user
        cardToken.mint(userAddr, 10);
        assertEq(cardToken.balanceOf(userAddr),10);

        // approve vault to spend userAddr tokens
        vm.prank(userAddr);
        cardToken.approve(address(vault), 100000);

        // lock 10 tokens
        vm.prank(userAddr);
        vault.lock(10);

        // assert user balance is 0, and vault is 10
        assertEq(cardToken.balanceOf(userAddr),0);
        assertEq(cardToken.balanceOf(address(vault)), 10);

        // try claiming after 1 year, expect full claim
        vm.prank(userAddr);
        vm.warp(block.timestamp + 365 days);
        vault.claimUnlockedTokens();
        assertEq(cardToken.balanceOf(userAddr),10);
        assertEq(cardToken.balanceOf(address(vault)), 0);
    }

    function testUserCanLockAgainAfterFullClaim() public {
        address userAddr = address(accounts.PUBLIC_KEYS(0));

        // mint 10 CARD tokens to user
        cardToken.mint(userAddr, 10);
        assertEq(cardToken.balanceOf(userAddr),10);

        // approve vault to spend userAddr tokens
        vm.prank(userAddr);
        cardToken.approve(address(vault), 100000);

        // lock 8 tokens
        vm.prank(userAddr);
        vault.lock(8);

        // assert user balance is 0, and vault is 8
        assertEq(cardToken.balanceOf(userAddr),2);
        assertEq(cardToken.balanceOf(address(vault)), 8);

        // try locking more, expect error
        vm.prank(userAddr);
        bytes memory expectedError = "user already has locked balance";
        vm.expectRevert(expectedError);
        vault.lock(2);

        // try claiming after 1 year, expect full claim
        vm.prank(userAddr);
        vm.warp(block.timestamp + 365 days);
        vault.claimUnlockedTokens();
        assertEq(cardToken.balanceOf(userAddr),10);
        assertEq(cardToken.balanceOf(address(vault)), 0);

        // confirm old lock is gone, and we can lock more tokens now
        vm.prank(userAddr);
        vault.lock(2);
        assertEq(cardToken.balanceOf(userAddr),8);
        assertEq(cardToken.balanceOf(address(vault)), 2);
    }


    function testLockingAndClaimAfterHalfUnlock() public {
        address userAddr = address(accounts.PUBLIC_KEYS(0));

        // mint 10 CARD tokens to user
        cardToken.mint(userAddr, 10);
        assertEq(cardToken.balanceOf(userAddr),10);

        // approve vault to spend userAddr tokens
        vm.prank(userAddr);
        cardToken.approve(address(vault), 100000);

        // lock 10 tokens
        vm.prank(userAddr);
        vault.lock(10);

        // assert user balance is 0, and vault is 10
        assertEq(cardToken.balanceOf(userAddr),0);
        assertEq(cardToken.balanceOf(address(vault)), 10);

        // try claiming after 1 year, expect full claim
        vm.prank(userAddr);
        vm.warp(block.timestamp + 183 days);
        vault.claimUnlockedTokens();
        assertEq(cardToken.balanceOf(userAddr),5);
        assertEq(cardToken.balanceOf(address(vault)), 5);
    }

    function testLockingAndClaimEachMonthUntilFullyUnlocked() public {
        address userAddr = address(accounts.PUBLIC_KEYS(0));

        // mint 10 CARD tokens to user
        cardToken.mint(userAddr, 10);
        assertEq(cardToken.balanceOf(userAddr),10);

        // approve vault to spend userAddr tokens
        vm.prank(userAddr);
        cardToken.approve(address(vault), 100000);

        // lock 10 tokens
        vm.prank(userAddr);
        vault.lock(10);

        // assert user balance is 0, and vault is 10
        assertEq(cardToken.balanceOf(userAddr),0);
        assertEq(cardToken.balanceOf(address(vault)), 10);

        uint startTime = block.timestamp;
        vm.startPrank(userAddr);
        for (uint i = 0; i <= 12; i++) {
            vm.warp(startTime + 30 days * i);
            vault.claimUnlockedTokens();
            assertEq(cardToken.balanceOf(userAddr), (uint(10) * i) / 12);
        }
        vm.stopPrank();

        // by the end, the user balance shud be 10
        assertEq(cardToken.balanceOf(userAddr),10);
        assertEq(cardToken.balanceOf(address(vault)), 0);

        // TODO(what to do after locked vault is completely drained?
    }

    function testUnlockAfterPanic() public {
        address userAddr = address(accounts.PUBLIC_KEYS(0));

        // mint 10 CARD tokens to user
        cardToken.mint(userAddr, 10);
        assertEq(cardToken.balanceOf(userAddr),10);

        // approve vault to spend userAddr tokens
        vm.prank(userAddr);
        cardToken.approve(address(vault), 100000);

        // lock 10 tokens
        vm.prank(userAddr);
        vault.lock(10);

        // assert user balance is 0, and vault is 10
        assertEq(cardToken.balanceOf(userAddr),0);
        assertEq(cardToken.balanceOf(address(vault)), 10);

        // try claiming immediately, expect 0 claimed.
        vm.prank(userAddr);
        vault.claimUnlockedTokens();
        assertEq(cardToken.balanceOf(userAddr),0);
        assertEq(cardToken.balanceOf(address(vault)), 10);

        // panic, and expect full claim
        vault.setPanic(true);
        vm.prank(userAddr);
        vault.claimUnlockedTokens();
        assertEq(cardToken.balanceOf(userAddr),10);
        assertEq(cardToken.balanceOf(address(vault)), 0);

        // lock again, turn panic off, and expect 0 claim
        vm.prank(userAddr);
        vault.lock(10);
        assertEq(cardToken.balanceOf(userAddr),0);
        assertEq(cardToken.balanceOf(address(vault)), 10);
        vault.setPanic(false);
        vm.prank(userAddr);
        vault.claimUnlockedTokens();
        assertEq(cardToken.balanceOf(userAddr),0);
        assertEq(cardToken.balanceOf(address(vault)), 10);
    }

    function testLockMoreThanBalanceReverts() public {
        address userAddr = address(accounts.PUBLIC_KEYS(0));

        // assert starting balance is 0
        assertEq(cardToken.balanceOf(userAddr),0);

        // mint 10 CARD tokens to user
        cardToken.mint(userAddr, 10);
        assertEq(cardToken.balanceOf(userAddr),10);

        // approve vault to spend userAddr tokens
        vm.prank(userAddr);
        cardToken.approve(address(vault), 100000);

        // try to lock 11 CARD
        vm.prank(userAddr);
        vm.expectRevert(ERC20_INVALID_BALANCE);
        vault.lock(11);
    }

    function testBlackListedCantLock() public {
        address userAddr = address(accounts.PUBLIC_KEYS(0));

        // assert starting balance of user and vault is 0
        assertEq(cardToken.balanceOf(userAddr),0);
        assertEq(cardToken.balanceOf(address(vault)), 0);

        // mint 10 CARD tokens to user
        cardToken.mint(userAddr, 10);
        assertEq(cardToken.balanceOf(userAddr),10);

        // approve vault to spend userAddr tokens
        vm.prank(userAddr);
        cardToken.approve(address(vault), 100000);

        // add user to blacklist
        vault.addToBlacklist(userAddr);
        // try to lock tokens, expect error
        bytes memory expectedError = "blacklisted wallet";
        vm.expectRevert(expectedError);
        vm.prank(userAddr);
        vault.lock(10);

        // remove from blacklist and try locking
        vault.removeFromBlacklist(userAddr);
        vm.prank(userAddr);
        vault.lock(10);
    }


}