const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require('truffle-assertions');
var assert = require('assert');

const Regulator = artifacts.require("Regulator");
const UserDataStorage = artifacts.require("UserDataStorage");
const Company = artifacts.require("Company")

contract("Carbon Contract", function (accounts) {
    before(async () => {
        regulatorInstance = await Regulator.deployed();
        userDataStorageInstance = await UserDataStorage.deployed();
    });

    console.log("Initializing Preconditions")

    it("", async () => {
        
    })

    it("", async () => {
        await regulatorInstance.setUserDataStorageAddress(UserDataStorage.address);
        let a1 = await regulatorInstance.requestApproval("Tesla", { from: accounts[1] });
        truffleAssert.eventEmitted(a1, 'approvalRequested')
    })

    
});
