// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import { BaseTest, console } from "./base/BaseTest.t.sol";
import {CardToken} from "../main/CardToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultTest is BaseTest {

    CardToken cardToken;
	function setUp() public {
        cardToken = new CardToken();
    }

	function testStakeAndUnstakeCARD() public {
        address userAddr = address(accounts.PUBLIC_KEYS(0));
		console.log("user addr:", userAddr);

        // assert starting balance is 0
        assertEq(cardToken.balanceOf(userAddr),0);

        // mint 10 CARD tokens to user
        cardToken.mint(userAddr, 10);
        assertEq(cardToken.balanceOf(userAddr),10);
	}
}
