// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Vault is ReentrancyGuard {

    struct User {
        uint256 stakedAmount;
        // uint256 rewardsClaimedAmount;
        uint256 lockedAtTimestamp;
        uint256 lockedAmount;
    }

    mapping(address => User) public users;

    address public immutable cartTokenAddr;

    uint64 public lastSyncBlockNumber;

    constructor(
        address _cardTokenAddr
    ) {
        // verify the inputs are set
        require(_cardTokenAddr != address(0), "_cardTokenAddr not set");

        // save the inputs into internal state variables
        cartTokenAddr = _cardTokenAddr;
    }

    function _sync() private {

        uint256 currentBlock = blockNumber();
        if (currentBlock <= lastSyncBlockNumber) {
            // if already synced, return silently
            return;
        }

        // update rewards in Users
        // determine how many blocks have passed since last block
        // uint256 blocksElapsed = currentBlock - lastSyncBlockNumber;

        lastSyncBlockNumber = uint64(currentBlock);
    }

    function stake(
        uint256 _amount
    ) external {
        require(_amount > 0, "requires amount > 0");

        // sync state
        _sync();

        // add an entry for the user
        User storage user = users[address(msg.sender)];

        require(user.lockedAtTimestamp <= 0, "Cant stake more IF you have locked");

        uint256 prevVaultTokenBalance = IERC20(cardTokenAddr).balanceOf(address(this));
        SafeERC20.safeTransferFrom(IERC20(cardTokenAddr), address(msg.sender), address(this), _amount);
        uint256 newVaultTokenBalance = IERC20(cardTokenAddr).balanceOf(address(this));
        uint256 addedAmount = newVaultTokenBalance - prevVaultTokenBalance;

        user.stakedAmount += addedAmount;

        emit Staked(msg.sender, _amount, addedAmount, user.stakedAmount);
    }


    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount,
        bool _useSILV
    ) internal virtual  {

    }

    function claimUnlockedTokens() public {
        User storage user = users[msg.sender];

    }


    function blockNumber() public view virtual returns (uint256) {
        // return current block number
        return block.number;
    }

    function now256() public view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }


}