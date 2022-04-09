const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require('truffle-assertions');
var assert = require('assert');

const Regulator = artifacts.require("Regulator");
const UserDataStorage = artifacts.require("UserDataStorage");
const Company = artifacts.require("Company")

contract("Workflow 1", function(accounts) {
    before(async() => {
        regulatorInstance = await Regulator.deployed();
        userDataStorageInstance = await UserDataStorage.deployed();
        companyInstance = await Company.deployed();
    });

console.log("Testing Onboarding")

it("Governing body (UN) adds a regulator", async()=> {
    //set user data storage address in regulator instance
    await regulatorInstance.setUserDataStorageAddress(UserDataStorage.address);

    //set user data storage address in company instance
    await companyInstance.setUserDataStorageAddress(UserDataStorage.address);

    // show that other addresses cannot set the regulator and company address?
    //set regulator contract address in user data storage instance
    await userDataStorageInstance.setRegulatorContract(Regulator.address);

    //set company contract address in user data storage instance 
    await userDataStorageInstance.setCompanyContract(Company.address);

    //Only the governing body (accounts[0]) can add a regulator --> calling addRegulator from 
    //other addresses will fail.
    await truffleAssert.fails(
        regulatorInstance.addRegulator('Climate Change Committee', 'UK', accounts[1], {from: accounts[1]}),
        truffleAssert.ErrorType.REVERT,
        "Only Governing Body (owner) is allowed to do this."
    );

    //add regulator for real
    await regulatorInstance.addRegulator('Climate Change Committee', 'UK', accounts[1], {from: accounts[0]})
    
    //check that account 1 is authorised 
    let auth = await userDataStorageInstance.isAuthorisedRegulator(accounts[1])
    assert.strictEqual(
        auth,
        true,
        "Account not added successfully"
    )

    //once regulator has been added, error raised if tried to add again
    await truffleAssert.fails(
        regulatorInstance.addRegulator('Climate Change Committee', 'UK', accounts[1], {from: accounts[0]}),
        truffleAssert.ErrorType.REVERT,
        "Regulator is already authorised!"
    );

})

it("Regulator adds a company", async()=> {
    //Only the regulator (accounts[1]) can add a company --> calling addCompany from 
    //other addresses will fail.
    await truffleAssert.fails(
        companyInstance.addCompany('Apple Inc.', accounts[2], {from: accounts[3]}),
        truffleAssert.ErrorType.REVERT,
        'Only approved regulators are allowed to do this.'
    );

    //add company for real
    await companyInstance.addCompany('Apple Inc', accounts[2], {from: accounts[1]})
    
    //check that account 2 is authorised 
    let auth = await companyInstance.isAuthorised(accounts[2])
    assert.strictEqual(
        auth,
        true,
        "Account not added successfully"
    )

    //once company has been added, error raised if tried to add again
    await truffleAssert.fails(
        companyInstance.addCompany('Apple Inc.', accounts[2], {from: accounts[1]}),
        truffleAssert.ErrorType.REVERT,
        'Address is already an approved Company!'
    );

})

});
