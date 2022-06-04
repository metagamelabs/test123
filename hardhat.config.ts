import { secrets } from "./.secrets"

import { HardhatUserConfig, subtask } from "hardhat/config"
import { TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } from "hardhat/builtin-tasks/task-names"

import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-waffle"
import "@typechain/hardhat"
import "@openzeppelin/hardhat-upgrades"
import "hardhat-preprocessor"

import fs from "fs"

subtask(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS).setAction(
	async (_, __, runSuper) => {
		const paths = await runSuper()
		return paths.filter(
			(p: string) => !p.endsWith(".t.sol") || p.includes("/mock/")
		)
	}
)

const config: HardhatUserConfig = {
	defaultNetwork: "localhost",
	networks: {
		localhost: {
			url: "http://localhost:8545",
		},
		rinkeby: {
			url: secrets.networks.rinkeby!.RPC_URL || "",
			accounts: [secrets.networks.rinkeby!.PRIVATE_KEY],
		},
		mainnet: {
			url: secrets.networks.mainnet!.RPC_URL,
			accounts: [secrets.networks.mainnet!.PRIVATE_KEY],
		},
	},
	etherscan: {
		apiKey: {
			mainnet: secrets.networks.mainnet!.ETHERSCAN_API_KEY,
			rinkeby: secrets.networks.rinkeby!.ETHERSCAN_API_KEY,
		},
	},
	solidity: {
		version: "0.8.13",
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
	paths: {
		sources: "./src",
		tests: "./test",
		cache: "./hardhat/cache",
		artifacts: "./hardhat/artifacts",
	},
	preprocess: {
		eachLine: (hre) => ({
			transform: (line: string) => {
				if (line.match(/^\s*import /i)) {
					getRemappings().forEach(([find, replace]) => {
						if (line.match('"' + find)) {
							line = line.replace('"' + find, '"' + replace);
						}
					});
				}
				return line;
			},
		}),
	},
}

// Hardhat Compatibility instructions from https://book.getfoundry.sh/config/hardhat.html
function getRemappings() {
	return fs
		.readFileSync("remappings.txt", "utf8")
		.split("\n")
		.filter(Boolean) // remove empty lines
		.map((line) => line.trim().split("="));
}

export default config