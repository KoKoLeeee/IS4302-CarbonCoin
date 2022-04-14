const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require('truffle-assertions');
var assert = require('assert');


const Regulator = artifacts.require("Regulator");
const UserDataStorage = artifacts.require("UserDataStorage");
const Company = artifacts.require("Company");
const ProjectStorage = artifacts.require("ProjectStorage");
const Project = artifacts.require("Project");
const CarbonToken = artifacts.require("CarbonToken");


contract("Projects", function(accounts) {
    before(async() => {
        userDataStorageInstance = await UserDataStorage.deployed();
        regulatorInstance = await Regulator.deployed();
        companyInstance = await Company.deployed();
        projectStorageInstance = await ProjectStorage.deployed();
        projectInstance = await Project.deployed();
        carbonTokenInstance = await CarbonToken.deployed();
    });


it("Setting Address of Company and Regulator in UserDataStorage", async () => {
    console.log("Initializing Preconditions")
    let s1 = await userDataStorageInstance.setCompanyContract(companyInstance.address);
    truffleAssert.eventEmitted(s1, 'CompanyAddressSet');

    let s2 = await userDataStorageInstance.setRegulatorContract(regulatorInstance.address);
    truffleAssert.eventEmitted(s2, 'RegulatorAddressSet');
    
})


it("Setting Address of Project in ProjectStorage", async () => {
    let s3 = await projectStorageInstance.setProjectAddress(projectInstance.address);
    truffleAssert.eventEmitted(s3, 'ProjectAddressSet');
})

it("Adding a regulator (accounts[1])", async() => {
    await regulatorInstance.approveRegulator('Climate Change Committee', 'UK', accounts[1], {from: accounts[0]})
    let auth = await regulatorInstance.isApproved(accounts[1])
    assert.strictEqual(
        auth,
        true,
        "Account not added successfully"
    )

})

it('Adding a company (accounts[2])', async() => {
    await companyInstance.approveCompany('Apple Inc', accounts[2], {from: accounts[1]})
    //check that account 2 is authorised 
    let auth = await companyInstance.isApproved(accounts[2])
    assert.strictEqual(
        auth,
        true,
        "Account not added successfully"
    )
})

it('Company (accounts[2]) requests a project - "eco-friendly machines" to be approved, project id should be 0 since it is the first project in the system', async() => {
    console.log("Requesting of projects");
    let r1 = await projectInstance.requestProject("eco-friendly machines", {from: accounts[2]});
    truffleAssert.eventEmitted(r1, "projectRequested", (ev) => {
        return ev.requester == accounts[2] && ev.projectName == 'eco-friendly machines' && ev.projId == 0
    });
})

it('Company (accounts[2]) requests another project - "carbon-efficient reactor" to be approved, project id should be 1 since it is the second project in the system', async() => {
    let r2 = await projectInstance.requestProject("carbon-efficient reactor", {from: accounts[2]});
    truffleAssert.eventEmitted(r2, "projectRequested", (ev) => {
        return ev.requester == accounts[2] && ev.projectName == 'carbon-efficient reactor' && ev.projId == 1
    });

})

it("Project status for both eco-friendly machines and carbon-efficient reactor should be 'requested'", async() => {
    let status1 = await projectInstance.getProjectStatus(0); //proj id of eco-friendly machines is 0; checked above
    let status2 = await projectInstance.getProjectStatus(1); //proj id of carbon-efficient reactor is 1; checked above

    //check that project status is 'Requested' --> 0 in the enum 
    assert.strictEqual(
        status1.toString(),
        '0',
        "Requested project does not have status requested!"
    );

    assert.strictEqual(
        status2.toString(),
        '0',
        "Requested project does not have status requested!"
    );

    //Postcondition: There are 2 projects with 'Requested' status pending for the regulator to approve now.
})


it("Regulator (accounts[1]) rejects the carbon-efficient reactor project", async() => {
    console.log("Rejection of projects");
    //reject carbon-efficient reactor for real with correct regulator account
    let r1 = await projectInstance.rejectProject('1', {from: accounts[1]});
    truffleAssert.eventEmitted(r1, 'projectRejected');
})

it("Status of the carbon-efficient reactor project (id 1) should be 'Rejected' (enum index 2)", async() => {
    let status2 = await projectInstance.getProjectStatus('1');
    assert.strictEqual(
        status2.toString(),
        '2',
        "carbon-efficient reactor not rejected"
    );
})


it("Regulator (accounts[1]) approves the eco-friendly machines project", async()=> { 
    console.log("Approval of projects");
    //approve eco-friendly machines project (id 0) with 5 carbon tokens to be awarded
    let a1 = await projectInstance.approveProject('0', 5, {from: accounts[1]});
    truffleAssert.eventEmitted(a1, 'projectApproved', (ev) => {
        return ev.approver == accounts[1] && ev.projId == 0 && ev.awardedTokens == 5
    });
})

it("Status of the eco-friendly machines project (id 0) should be 'Approved' (enum index 1)", async() => {
    let status1 = await projectInstance.getProjectStatus('0');
    assert.strictEqual(
        status1.toString(),
        '1',
        "eco-friendly machines not approved"
        );
})


it("Regulator (accounts[1]) mints 5 tokens for the Company (accounts[2])", async() => {
    console.log("Awarding of tokens to Company after approval of project");
    let m1 = await carbonTokenInstance.mintForProject('0', {from: accounts[1]});
    truffleAssert.eventEmitted(m1, 'mintedForProject');
})

it("Company (accounts[2]) token balance should reflect 5 tokens (initially is 0)", async() => {
    let b1 = await carbonTokenInstance.getTokenBalance(accounts[2]);
    assert.strictEqual(
        b1.toString(),
        '5',
        "Tokens were not minted for Apple Inc."
    )
})

});
