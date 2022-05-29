// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CardToken is ERC20("CardToken", "CART"), Ownable {

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

}
