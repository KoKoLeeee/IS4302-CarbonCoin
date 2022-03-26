const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require('truffle-assertions');
var assert = require('assert');

const Regulator = artifacts.require("Regulator");
const UserDataStorage = artifacts.require("UserDataStorage");
const Company = artifacts.require("Company")

contract("Regulator", function(accounts) {
    before(async() => {
        regulatorInstance = await Regulator.deployed();
        userDataStorageInstance = await UserDataStorage.deployed();
    });

console.log("Testing Regulator Contract")

it("Regulator requests approval", async()=> {
    await regulatorInstance.setUserDataStorageAddress(UserDataStorage.address);
    let a1 = await regulatorInstance.requestApproval("Tesla", {from: accounts[1]});
    truffleAssert.eventEmitted(a1, 'approvalRequested')
})

it("Requesting regulator has authorisation = false initially", async() => {
    let auth = await regulatorInstance.isAuthorised(accounts[1], {from: accounts[0]});
    assert.strictEqual(
        auth,
        false,
        "Authorisation is not false"
    )
})

it("Owner approves regulator, changes authorisation status to true", async() => {
    await regulatorInstance.approveRegulator(accounts[1], {from: accounts[0]});
    let auth = await regulatorInstance.isAuthorised(accounts[1])
    assert.strictEqual(
        auth,
        true,
        "Authorisation not changed to true"
    )
})

it("Remove regulator", async() =>{
    await regulatorInstance.removeRegulator(accounts[1], {from: accounts[0]});
    let auth = await regulatorInstance.isAuthorised(accounts[1]);
    assert.strictEqual(
        auth,
        false,
        "Regulator not removed"
    )
})

it("Only owner can approve, reject and remove regulator", async() => {
    //company requests approval
    let t1 = await regulatorInstance.requestApproval("Aramco",{from: accounts[2]});
    truffleAssert.eventEmitted(t1, "approvalRequested");
    //only owner can reject approval - use accounts[1] to reject
    await truffleAssert.fails(
        regulatorInstance.rejectRegulator(accounts[2], {from: accounts[1]}),
        truffleAssert.ErrorType.REVERT,
        "Only owner is allowed to do this."
    );
    //reject approval for real so we can request again
    await regulatorInstance.rejectRegulator(accounts[2], {from:accounts[0]})
    //company requests approval
    let t2 = await regulatorInstance.requestApproval("Aramco",{from: accounts[2]});
    truffleAssert.eventEmitted(t2, "approvalRequested");
    //only owner can approve - use accounts[1] to approve
    await truffleAssert.fails(
        regulatorInstance.approveRegulator(accounts[2], {from: accounts[1]}),
        truffleAssert.ErrorType.REVERT,
        "Only owner is allowed to do this."
    );
    //only owner can remove - use accounts [1] to remove
    await truffleAssert.fails(
        regulatorInstance.removeRegulator(accounts[2], {from: accounts[1]}),
        truffleAssert.ErrorType.REVERT,
        "Only owner is allowed to do this."
        
    );
    })
});

contract("Company", function(accounts) {
    before(async() => {
        regulatorInstance = await Regulator.deployed();
        userDataStorageInstance = await UserDataStorage.deployed();
        companyInstance = await Company.deployed();
    });

console.log("Testing Company Contract");

it("Company requests approval", async()=> {
    await regulatorInstance.setUserDataStorageAddress(UserDataStorage.address);
    await companyInstance.setUserDataStorageAddress(UserDataStorage.address);

    //first make sure there is an approved regulator
    await regulatorInstance.requestApproval("Regulator 1", {from: accounts[1]});
    await regulatorInstance.approveRegulator(accounts[1], {from: accounts[0]});
    //company requests approval
    let a1 = await companyInstance.requestApproval("Tesla", {from: accounts[2]});
    truffleAssert.eventEmitted(a1, 'approvalRequested')
})

it("Requesting company has authorisation = false initially", async() => {
    let auth = await companyInstance.isAuthorised(accounts[2], {from: accounts[0]});
    assert.strictEqual(
        auth,
        false,
        "Authorisation is not false"
    )
})

it("Approved regulator approves company, changes authorisation status to true", async() => {
    await companyInstance.approveCompany(accounts[2], {from: accounts[1]});
    let auth = await companyInstance.isAuthorised(accounts[2])
    assert.strictEqual(
        auth,
        true,
        "Authorisation not changed to true"
    )
})

it("Only an approved regulator (accounts[1]) can approve, reject and remove company", async() => {
    //company requests approval. company is accounts[4]
    let t1 = await companyInstance.requestApproval("Aramco", {from: accounts[4]});
    truffleAssert.eventEmitted(t1, "approvalRequested");
    //only approved regulator can reject approval - use accounts[5] to reject
    await truffleAssert.fails(
        companyInstance.rejectCompany(accounts[4], {from: accounts[5]}),
        truffleAssert.ErrorType.REVERT,
        "Only approved regulators are allowed to do this."
    );
    //reject request for real so we can request again
    await companyInstance.rejectCompany(accounts[4], {from:accounts[1]})
    //company requests approval
    let t2 = await companyInstance.requestApproval("Aramco",{from: accounts[4]});
    truffleAssert.eventEmitted(t2, "approvalRequested");
    //only approved regulator can approve - use accounts[5] to approve
    await truffleAssert.fails(
        companyInstance.approveCompany(accounts[4], {from: accounts[5]}),
        truffleAssert.ErrorType.REVERT,
        "Only approved regulators are allowed to do this."
    );
    //only approved regulator can remove - use accounts [5] to remove
    await truffleAssert.fails(
        companyInstance.removeCompany(accounts[4], {from: accounts[5]}),
        truffleAssert.ErrorType.REVERT,
        "Only approved regulators are allowed to do this."
        
    );
    })
});
