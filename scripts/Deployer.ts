import { IDeployConfig } from "./config/DeployConfig"
import { DeploymentHelper } from "./utils/DeploymentHelper"
import { ethers } from "hardhat"

export class Deployer {
	config: IDeployConfig
	helper: DeploymentHelper

	constructor(config: IDeployConfig) {
		this.config = config
		this.helper = new DeploymentHelper(config)
	}

	async run() {
		await this.helper.initHelper()

		const CardToken = await ethers.getContractFactory("CardToken")
		const cardTokenContract = await this.helper.deployContract(
			CardToken,
			"CardToken"
		)

		const Vault = await ethers.getContractFactory("Vault")
		const vaultContract = await this.helper.deployContract(Vault, "Vault", cardTokenContract.address);
	}
}