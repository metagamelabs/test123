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

        // unstake tokens
	}

    function testStakeMoreThanBalance() public {
        address userAddr = address(accounts.PUBLIC_KEYS(0));
		console.log("user addr:", userAddr);

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
    }
}
