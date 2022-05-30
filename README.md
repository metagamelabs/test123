Starting template from https://github.com/0xAtum/template-solidity-project

# Staking Contract Design
## Resources
- https://github.com/OpenZeppelin/openzeppelin-contracts/issues/2457 for staking contract examples

## Yam Finance
https://github.com/yam-finance/yam-protocol/blob/master/contracts/distribution/YAMAMPLPool.sol

`contract YAMAMPLPool is LPTokenWrapper, IRewardDistributionRecipient`
The Vault
    - calls the LPToken (through LPTokenWrapper)
    - can stake and unstake anytime
    - stake() withdraw() exit()

## SNX

## Illuvium Pool
https://etherscan.io/address/0x8b4d8443a0229349a9892d4f7cbe89ef5f843f72#code

- has time locked staking
- stake() unstake()



# Assumptions
- User can't add more to the stake. Initial stake is done and lasts for one year.
- Stake time is 1 year
- stake/unstake and lock are separate. staking doesn't require locking.
- Card feature is not related to the staking. 



