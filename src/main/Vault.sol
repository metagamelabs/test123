// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Vault is ReentrancyGuard, Ownable {

    struct UserTokenLock {
        uint256 lockedAmount;
        uint256 lockedAtTimestamp;
        uint256 claimedAmount;
    }

    mapping(address => UserTokenLock) public userTokenLocks;

    mapping(address => uint256) public userStakeAmountMap;

    address public immutable cardTokenAddr;

    mapping (address => bool) public walletBlacklist;

    uint64 public lastSyncBlockNumber;

    bool isPanic;

    event Staked(address indexed _staker, uint256 _amount, uint256 _actualAmount, uint256 _newStakedAmount);
    event Debug(string text, uint a, uint b);
    event Unstaked(address _requestedBy, address indexed _staker, uint256 _amount, uint256 _newStakedAmount);
    event Locked(address _locker, uint256 _amount, uint256 _actualAmount);
    event ClaimedUnlocked(address _claimer, uint256 _amount, uint monthsElapsed, uint256 _totalClaimed);

    constructor(
        address _cardTokenAddr
    ) {
        // verify the inputs are set
        require(_cardTokenAddr != address(0), "_cardTokenAddr not set");

        // save the inputs into internal state variables
        cardTokenAddr = _cardTokenAddr;
    }

    function addToBlacklist(address badAddr) external onlyOwner {
        walletBlacklist[badAddr] = true;
    }

    function removeFromBlacklist(address addr) external onlyOwner {
        walletBlacklist[addr] = false;
    }

    function stake(
        uint256 _amount
    ) external {
        require(_amount > 0, "requires amount > 0");

        uint256 prevVaultTokenBalance = IERC20(cardTokenAddr).balanceOf(address(this));
        SafeERC20.safeTransferFrom(IERC20(cardTokenAddr), address(msg.sender), address(this), _amount);
        uint256 newVaultTokenBalance = IERC20(cardTokenAddr).balanceOf(address(this));
        uint256 addedAmount = newVaultTokenBalance - prevVaultTokenBalance;

        userStakeAmountMap[msg.sender] += addedAmount;

        emit Staked(msg.sender, _amount, addedAmount, userStakeAmountMap[msg.sender]);
    }


    function unstake(
        address _stakerAddr,
        uint256 _amount
    ) external  {
        require(_amount > 0, "requires amount > 0");

        require(userStakeAmountMap[_stakerAddr] > 0, "no staked balance to unstake");

        require(_amount <= userStakeAmountMap[_stakerAddr], "requires input _amount <= user.stakedAmount");
        SafeERC20.safeTransfer(IERC20(cardTokenAddr), _stakerAddr, _amount);

        userStakeAmountMap[_stakerAddr] -= _amount;

        emit Unstaked(msg.sender, _stakerAddr, _amount, userStakeAmountMap[_stakerAddr]);
    }

    function lock(uint256 _amount) external {
        require(!walletBlacklist[msg.sender], "blacklisted wallet");

        UserTokenLock storage utl = userTokenLocks[msg.sender];

        require(utl.lockedAtTimestamp <= 0 && utl.lockedAmount == 0, "user already has locked balance");
        
        uint256 prevVaultTokenBalance = IERC20(cardTokenAddr).balanceOf(address(this));
        SafeERC20.safeTransferFrom(IERC20(cardTokenAddr), address(msg.sender), address(this), _amount);
        uint256 newVaultTokenBalance = IERC20(cardTokenAddr).balanceOf(address(this));
        uint256 lockedAmount = newVaultTokenBalance - prevVaultTokenBalance;

        utl.lockedAmount = lockedAmount;
        utl.lockedAtTimestamp = now256();

        emit Locked(msg.sender, _amount, lockedAmount);
    }

    function claimUnlockedTokens() external {
        UserTokenLock storage utl = userTokenLocks[msg.sender];

        require(utl.lockedAmount > 0, "no locked tokens");

        // determine months since initial lock
        uint256 timeElapsed = now256() - utl.lockedAtTimestamp;
        uint monthsElapsed = timeElapsed / 30 days;
        uint newClaimAmount;
        if (monthsElapsed >= 12 || isPanic) {
            // unlock all tokens
            // TODO also test wjat jap[[emns when i call claim twice for this block of code
            newClaimAmount = utl.lockedAmount - utl.claimedAmount;
        } else if (monthsElapsed == 0) {
            // no tokens to claim;
            return;
        } else {
            uint totalUnlockedTokens = utl.lockedAmount * monthsElapsed / 12;
            newClaimAmount = totalUnlockedTokens - utl.claimedAmount;
        }
        SafeERC20.safeTransfer(IERC20(cardTokenAddr), msg.sender, newClaimAmount);

        utl.claimedAmount += newClaimAmount;

        emit ClaimedUnlocked(msg.sender, newClaimAmount, monthsElapsed, utl.claimedAmount);

        if (utl.lockedAmount == utl.claimedAmount) {
            // delete this lock so that the user can start a new lock in the future
            delete userTokenLocks[msg.sender];
        }
    }

    function setPanic(bool _isPanic) external onlyOwner {
        isPanic = _isPanic;
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
