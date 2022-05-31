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

    address public immutable cardTokenAddr;

    uint64 public lastSyncBlockNumber;

    event Staked(address indexed _staker, uint256 _amount, uint256 _actualAmount, uint256 _newStakedAmount);
    event Debug(string text);
    event Unstaked(address _requestedBy, address indexed _staker, uint256 _amount, uint256 _newStakedAmount);

    constructor(
        address _cardTokenAddr
    ) {
        // verify the inputs are set
        require(_cardTokenAddr != address(0), "_cardTokenAddr not set");

        // save the inputs into internal state variables
        cardTokenAddr = _cardTokenAddr;
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


    function unstake(
        address _stakerAddr,
        uint256 _amount
    ) external  {
        require(_amount > 0, "requires amount > 0");

        User storage user = users[_stakerAddr];

        require(user.stakedAmount > 0, "no staked balance to unstake");
        require(user.lockedAtTimestamp <= 0, "can't unstake if you have locked");

        require(_amount <= user.stakedAmount, "requires input _amount <= user.stakedAmount");
        SafeERC20.safeTransfer(IERC20(cardTokenAddr), _stakerAddr, _amount);

        user.stakedAmount -= _amount;

        emit Unstaked(msg.sender, _stakerAddr, _amount, user.stakedAmount);
    }

    function lock() external {
        
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
