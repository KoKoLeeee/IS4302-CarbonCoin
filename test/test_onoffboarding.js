const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require('truffle-assertions');
var assert = require('assert');

const Regulator = artifacts.require("Regulator");
const UserDataStorage = artifacts.require("UserDataStorage");
const Company = artifacts.require("Company")
const CarbonToken = artifacts.require("CarbonToken");


contract("Onboarding and Offboarding", function(accounts) {
    before(async() => {
        regulatorInstance = await Regulator.deployed();
        userDataStorageInstance = await UserDataStorage.deployed();
        companyInstance = await Company.deployed();
        carbonTokenInstance = await CarbonToken.deployed();
    });

it("Only the governing body (accounts[0]) can set the Regulator contract address in User Data Storage instance. Using other accounts (accounts[1]) fails", async()=> {
    
    console.log("Testing setting of addresses");
    await truffleAssert.fails(
       userDataStorageInstance.setRegulatorContract(regulatorInstance.address, {from: accounts[1]}),
        truffleAssert.ErrorType.REVERT,
        "Only the owner can set the regulator/contract address"
    );
})

it("Governing body (accounts[0]) sets the Regulator contract address in the User Data Storage instance", async() => {

    let s1 = await userDataStorageInstance.setRegulatorContract(regulatorInstance.address, {from: accounts[0]});
    truffleAssert.eventEmitted(s1, 'RegulatorAddressSet');
})

it("Only the governing body (accounts[0]) can set the Company contract address in User Data Storage instance. Using other accounts (accounts[1]) fails", async() => {

    await truffleAssert.fails(
        userDataStorageInstance.setCompanyContract(companyInstance.address, {from: accounts[1]}),
         truffleAssert.ErrorType.REVERT,
         "Only the owner can set the regulator/contract address"
     );
})
    
it("Governing body (accounts[0]) sets the Company contract address in the User Data Storage instance", async() => {

    let s2 = await userDataStorageInstance.setCompanyContract(companyInstance.address);
    truffleAssert.eventEmitted(s2, "CompanyAddressSet");
})


it("Only the governing body (accounts[0]) can add a Regulator. Using other accounts (accounts[1]) fails", async() => {
    
    console.log("Testing adding of Regulator by governing body");
    await truffleAssert.fails(
        regulatorInstance.approveRegulator('Climate Change Committee', 'UK', accounts[1], {from: accounts[1]}),
        truffleAssert.ErrorType.REVERT,
        "Only Governing Body (owner) is allowed to do this."
    );
})

it("Governing body (accounts[0]) adds a Regulator (accounts[1])", async() => {

    let a1 = await regulatorInstance.approveRegulator('Climate Change Committee', 'UK', accounts[1], 
    {from: accounts[0]})
    truffleAssert.eventEmitted(a1, "ApprovedRegulator");
})

it("Regulator (accounts[1]) approval status is now 'true'", async() => {

    let auth = await regulatorInstance.isApproved(accounts[1])
    assert.strictEqual(
        auth,
        true,
        "Account not added successfully"
    )
})

it("Once a Regulator (accounts[1]) has been added, trying to add it again fails", async() =>{

    await truffleAssert.fails(
        regulatorInstance.approveRegulator('Climate Change Committee', 'UK', accounts[1], {from: accounts[0]}),
        truffleAssert.ErrorType.REVERT,
        "Regulator is already authorised!"
    );
})


it("Only a Regulator (accounts[1]) is able to add a Company (accounts[2]). Using other accounts (accounts[3]) fails", async()=> {

    console.log("Testing adding of Company by Regulator")
    await truffleAssert.fails(
        companyInstance.approveCompany('Apple Inc.', accounts[2], {from: accounts[3]}),
        truffleAssert.ErrorType.REVERT,
        'Only approved regulators are allowed to do this.'
    );
})

it("Regulator (accounts[1]) adds a Company (accounts[2])", async() => {

    let a2 = await companyInstance.approveCompany('Apple Inc', accounts[2], {from: accounts[1]})
    truffleAssert.eventEmitted(a2, "ApprovedCompany");
})

it("Company (accounts[2]) approval status is now 'true'", async() => {

    let auth = await companyInstance.isApproved(accounts[2])
    assert.strictEqual(
        auth,
        true,
        "Account not added successfully"
    )
})

it("Once a Company (accounts[2]) has been added, adding it again fails", async() => {

    await truffleAssert.fails(
        companyInstance.approveCompany('Apple Inc.', accounts[2], {from: accounts[1]}),
        truffleAssert.ErrorType.REVERT,
        'Address is already an approved Company!'
    );
})

it("Only a Regulator (accounts[1]) can update the Company (accounts[2]) yearly limit. Using other accounts (accounts[3]) fails", async() => {
    console.log("Testing updating of Company (accounts[2]) emission limits and subsequent issuing of tokens."); 
    await truffleAssert.fails(
        companyInstance.updateYearlyLimit(accounts[2], 2022, 50, {from: accounts[3]}),
        truffleAssert.ErrorType.REVERT,
        'Only approved regulators are allowed to do this.'
    );
})

it("Regulator (accounts[1]) updates the Company (accounts[2]) yearly limit to be 50 tons for year 2022", async() => {
    let e1 = await companyInstance.updateYearlyLimit(accounts[2], 2022, 50, {from: accounts[1]});
    truffleAssert.eventEmitted(e1, "YearlyLimitUpdated");
})

it("Company (accounts[2]) 2022 limit should reflect 50 tons", async() => {
    let l1 = await companyInstance.getYearLimit(accounts[2], 2022);
    assert.strictEqual(
        l1.toString(),
        "50",
        "Yearly limit not updated correctly"
    )
})

it("Only a Regulator (accounts[1]) can carry out the yearly issuing of tokens to the Company (accounts[2]) based on their emission limit. Using other accounts (accounts[3]) fails", async() => {
    await truffleAssert.fails(
        carbonTokenInstance.mintForYear(accounts[2], 2022, {from: accounts[3]}),
        truffleAssert.ErrorType.REVERT,
        'Not authorised as a Regulator!'
    );
})

it("Regulator (accounts[1]) issues 50 tokens to Company (accounts[2]) based on their 2022 limit of 50 tons", async() => {
    let i1 = await carbonTokenInstance.mintForYear(accounts[2], 2022, {from: accounts[1]});
    truffleAssert.eventEmitted(i1, "mintedForYear");
})

it("Company (accounts[2]) token balance should reflect 50 tokens", async() => {
    let t1 = await carbonTokenInstance.getTokenBalance(accounts[2]);
    assert.strictEqual(
        t1.toString(),
        '50',
        "Tokens issued unsuccessfully"
    )
})

it("Only the Regulator (accounts[1]) can remove a Company (accounts[2]). Using other accounts (accounts[3]) fails", async() => {

    console.log("Testing removal of Company by Regulator")
    await truffleAssert.fails(
        companyInstance.removeCompany(accounts[2], {from: accounts[3]}),
        truffleAssert.ErrorType.REVERT,
        'Only approved regulators are allowed to do this.'
    );
})

it("If the Company (accounts[4]) isn't approved, it cannot be removed", async() => {

    await truffleAssert.fails(
        companyInstance.removeCompany(accounts[4], {from: accounts[1]}),
        truffleAssert.ErrorType.REVERT,
        'Address is not an approved company!'
    );
})

it("Regulator (accounts[1]) removes Company (accounts[2])", async() => {

    let r1 = await companyInstance.removeCompany(accounts[2], {from: accounts[1]});
    truffleAssert.eventEmitted(r1, "RemovedCompany");
})

it("Company (accounts[2]) approval status is changed to 'false'", async() => {

    let auth = await companyInstance.isApproved(accounts[2]);
    assert.strictEqual(
        auth,
        false,
        "Company is still approved!"
    );
})


it("Only the governing body (accounts[0]) can remove a Regulator (accounts[1]). Using other accounts (accounts[3]) fails", async() => {

    console.log("Testing removal of Regulator by the governing body")
    await truffleAssert.fails(
        regulatorInstance.removeRegulator(accounts[1], {from: accounts[3]}),
        truffleAssert.ErrorType.REVERT,
        "Only Governing Body (owner) is allowed to do this."
    );
})

it("If the Regulator (accounts[4]) isn't approved, it cannot be removed", async() => {

    await truffleAssert.fails(
        regulatorInstance.removeRegulator(accounts[4], {from: accounts[0]}),
        truffleAssert.ErrorType.REVERT,
        'Address is not an authorised regulator!'
    );
})

it("Governing body (accounts[0]) removes Regulator (accounts[1])", async() => {

    let r1 = await regulatorInstance.removeRegulator(accounts[1], {from: accounts[0]});
    truffleAssert.eventEmitted(r1, "RemovedRegulator");
})

it("Regulator (accounts[1]) approval status is changed to 'false'", async() => {

    let auth = await regulatorInstance.isApproved(accounts[1]);
    assert.strictEqual(
        auth,
        false,
        "Regulator is still approved!"
    );
})
});
