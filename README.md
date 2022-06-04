This uses a solidity-foundry-hardhat starting template from https://github.com/0xAtum/template-solidity-project

To run tests: `make test`

To start a local node: `npx hardhat node`

To run on local node: `make deploy-local` 


# Assumptions
- User can't add more to the lock. Initial lock lasts for one year. After lock is done, it is removed and a new lock can begin.
- Stake time is 1 year
- stake/unstake and lock are separate. staking doesn't require locking.
- Card feature is not related to the staking. 


# Not completed yet
- Upgradeable ERC20 instead of ERC20
- Card Feature
- Unit test scenarios with more than 1 account.



