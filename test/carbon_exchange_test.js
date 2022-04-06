const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require('truffle-assertions');
var assert = require('assert');
const { Console } = require("console");

const Regulator = artifacts.require("Regulator");
const UserDataStorage = artifacts.require("UserDataStorage");
const Company = artifacts.require("Company");
const ProjectStorage = artifacts.require("ProjectStorage");
const Project = artifacts.require("Project");// const ERC20 = artifacts.require("ERC20");
const CarbonToken = artifacts.require("CarbonToken");
const Wallet = artifacts.require("Wallet");
const TransactionData = artifacts.require("TransactionData");
const CarbonExchange = artifacts.require("CarbonExchange");


contract("Carbon Contract", function (accounts) {
    before(async () => {        
        userDataStorageInstance = await UserDataStorage.deployed();
        regulatorInstance = await Regulator.deployed();
        companyInstance = await Company.deployed();
        projectStorageInstance = await ProjectStorage.deployed();
        projectInstance = await Project.deployed();
        carbonTokenInstance = await CarbonToken.deployed();
        walletInstance = await Wallet.deployed();
        transactionDataInstance = await TransactionData.deployed();
        carbonExchangeInstance = await CarbonExchange.deployed();

    });

    console.log("Initializing Preconditions")

    it("Setting Address of Company and Regulator in UserDataStorage", async () => {
        let s1 = await userDataStorageInstance.setCompanyContract(companyInstance.address);
        truffleAssert.eventEmitted(s1, 'CompanyAddressSet');

        let s2 = await userDataStorageInstance.setRegulatorContract(regulatorInstance.address);
        truffleAssert.eventEmitted(s2, 'RegulatorAddressSet');
        
    })

    it("Setting Address of Project in ProjectStorage", async () => {
        let s3 = await projectStorageInstance.setProjectAddress(projectInstance.address);
        truffleAssert.eventEmitted(s3, 'ProjectAddressSet');
    })

    it("Setting Address of CarbonExchange in Wallet", async () => {
        let s4 = await walletInstance.setCarbonExchangeAddress(carbonExchangeInstance.address);
        truffleAssert.eventEmitted(s4, 'CarbonExchangeAddressSet');
    })

    it("Setting Address of CarbonExchange in TransactionData", async () => {
        let s5 = await transactionDataInstance.setCarbonExchangeAddress(carbonExchangeInstance.address);
        truffleAssert.eventEmitted(s5, 'CarbonExchangeAddressSet');
    })

    it("", async () => {
        await regulatorInstance.setUserDataStorageAddress(UserDataStorage.address);
        let a1 = await regulatorInstance.requestApproval("Tesla", { from: accounts[1] });
        truffleAssert.eventEmitted(a1, 'approvalRequested')
    })

    console.log("Testing Carbon Exchange Contract");

    it("", async () => {});
    
});
