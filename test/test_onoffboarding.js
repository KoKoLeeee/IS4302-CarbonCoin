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

it("Governing body (accounts[0]) sets the Regulator contract address in the User Data Storage instance", async() => {
    console.log("Initializing Conditions")
    let s1 = await userDataStorageInstance.setRegulatorContract(regulatorInstance.address, {from: accounts[0]});
    truffleAssert.eventEmitted(s1, 'RegulatorAddressSet');
})

    
it("Governing body (accounts[0]) sets the Company contract address in the User Data Storage instance", async() => {
    let s2 = await userDataStorageInstance.setCompanyContract(companyInstance.address);
    truffleAssert.eventEmitted(s2, "CompanyAddressSet");
})

it("Governing body (accounts[0]) adds a Regulator (accounts[1])", async() => {
    console.log("Adding of Regulator by governing body");
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

it("Regulator (accounts[1]) adds a Company (accounts[2])", async() => {
    console.log("Adding of Company by Regulator")
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

it("Regulator (accounts[1]) updates the Company (accounts[2]) yearly limit to be 50 tons for year 2022", async() => {
    console.log("Updating of Company emission limits and subsequent issuing of tokens."); 
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

it("Regulator (accounts[1]) removes Company (accounts[2])", async() => {
    console.log("Removal of Company by Regulator")
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

it("Governing body (accounts[0]) removes Regulator (accounts[1])", async() => {
    console.log("Removal of Regulator by the governing body")
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
