import { ContractFactory } from "ethers"
import { writeFileSync, existsSync } from "fs"
import { IDeployConfig } from "../config/DeployConfig"
import { colorLog, Colors } from "./ColorConsole"
import { ethers, upgrades, run } from "hardhat"

export class DeploymentHelper {
	private path: string = "./scripts/deployments/"
	private fileName: string = "NOT_INIT.json"
	private systemInitialized: boolean = false
	config: IDeployConfig
	deploymentState: { [id: string]: IDeploymentHistory } = {}

	constructor(config: IDeployConfig) {
		this.config = config
	}

	async initHelper() {
		if (this.systemInitialized) return

		const { name, chainId } = await ethers.provider.getNetwork()

		this.fileName = `${name}(${chainId})_deployment.json`
		this.systemInitialized = true

		if (!existsSync(this.path + this.fileName)) {
			return
		}

		this.deploymentState = require("../deployments/" + this.fileName)
	}

	async deployUpgradeableContractWithName(
		contractName: string,
		identityName: string,
		initializerFunctionName?: string,
		...args: Array<any>
	) {
		return this.deployUpgradeableContract(
			await ethers.getContractFactory(contractName),
			identityName,
			initializerFunctionName,
			...args
		)
	}

	async deployUpgradeableContract(
		contractFactory: ContractFactory,
		identityName: string,
		initializerFunctionName?: string,
		...args: Array<any>
	) {
		const [findOld, address] = await this.tryToGetSaveContractAddress(
			identityName
		)

		if (findOld) {
			return contractFactory.attach(address)
		}

		const contract =
			initializerFunctionName !== undefined
				? await upgrades.deployProxy(contractFactory, args, {
						initializer: initializerFunctionName,
				  })
				: await upgrades.deployProxy(contractFactory)

		this.deploymentState[identityName] = {
			address: contract.address,
			proxyAdmin: (await upgrades.admin.getInstance()).address,
		}

		colorLog(
			Colors.green,
			`Deployed ${identityName} at ${contract.address}`
		)

		this.saveDeployment()
		return contract
	}

	async deployContractByName(
		contractFileName: string,
		name?: string,
		...args: Array<any>
	) {
		return await this.deployContract(
			await ethers.getContractFactory(contractFileName),
			name !== undefined ? name : contractFileName,
			...args
		)
	}

	async deployContract(
		contractFactory: ContractFactory,
		contractName: string,
		...args: Array<any>
	) {
		const [findOld, address] = await this.tryToGetSaveContractAddress(
			contractName
		)

		if (findOld) {
			return contractFactory.attach(address)
		}

		const contractDeployer = await contractFactory.deploy(...args)
		const contract = await contractDeployer.deployed()

		this.deploymentState[contractName] = {
			address: contract.address,
		}

		this.saveDeployment()
		await this.verifyContract(contract.address, ...args)

		colorLog(
			Colors.green,
			`Deployed ${contractName} at ${contract.address}`
		)
		return contract
	}

	saveDeployment() {
		const deploymentStateJson = JSON.stringify(
			this.deploymentState,
			null,
			2
		)
		writeFileSync(this.path + this.fileName, deploymentStateJson)
	}

	async verifyContract(contractAddress: string, ...args: Array<any>) {
		try {
			await run("verify:verify", {
				address: contractAddress,
				constructorArguments: args,
			})
		} catch (e) {
			colorLog(Colors.red, `Failed to verify ${contractAddress}. ${e}`)
		}
	}

	async tryToGetSaveContractAddress(
		contractName: string
	): Promise<[boolean, string]> {
		if (!this.systemInitialized) await this.initHelper()

		if (this.deploymentState[contractName] !== undefined) {
			const address = this.deploymentState[contractName].address
			colorLog(
				Colors.green,
				`${contractName} already exists. Loading ${address}`
			)

			return [true, address]
		}

		return [false, ""]
	}

	async sendAndWaitForTransaction(txPromise: Promise<any>) {
		const tx = await txPromise
		const minedTx = await ethers.provider.waitForTransaction(
			tx.hash,
			this.config.TX_CONFIRMATIONS
		)

		if (!minedTx.status) {
			throw `Transaction failed ${txPromise}`
		} else {
			colorLog(
				Colors.blue,
				`${minedTx.transactionHash} minted successfully`
			)
		}
		return minedTx
	}
}

