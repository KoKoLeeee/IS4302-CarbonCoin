const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require('truffle-assertions');
var assert = require('assert');

const Regulator = artifacts.require("Regulator");
const UserDataStorage = artifacts.require("UserDataStorage");
const Company = artifacts.require("Company");
const ProjectStorage = artifacts.require("ProjectStorage");
const Project = artifacts.require("Project");
const CarbonToken = artifacts.require("CarbonToken");
const Wallet = artifacts.require("Wallet");
const TransactionData = artifacts.require("TransactionData");
const CarbonExchange = artifacts.require("CarbonExchange");



contract("Testing Security of Onboarding / Offboarding", function (accounts) {
    before(async () => {
        regulatorInstance = await Regulator.deployed();
        userDataStorageInstance = await UserDataStorage.deployed();
        companyInstance = await Company.deployed();
        carbonTokenInstance = await CarbonToken.deployed();
    });

    it("Only the governing body (accounts[0]) can set the Regulator contract address in User Data Storage instance. Using other accounts (accounts[1]) fails", async () => {

        console.log("Testing security of address initialization in user data storage");
        await truffleAssert.fails(
            userDataStorageInstance.setRegulatorContract(regulatorInstance.address, { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT,
            "Only the owner can set the regulator/contract address"
        );
        // set the address using the correct account
        await userDataStorageInstance.setRegulatorContract(regulatorInstance.address, { from: accounts[0] });

    })

    it("Only the governing body (accounts[0]) can set the Company contract address in User Data Storage instance. Using other accounts (accounts[1]) fails", async () => {

        await truffleAssert.fails(
            userDataStorageInstance.setCompanyContract(companyInstance.address, { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT,
            "Only the owner can set the regulator/contract address"
        );
        // set the address using the correct contract
        await userDataStorageInstance.setCompanyContract(companyInstance.address);

    })

    it("Only the governing body (accounts[0]) can add a Regulator. Using other accounts (accounts[1]) fails", async () => {

        console.log("Testing adding of Regulator by governing body");
        await truffleAssert.fails(
            regulatorInstance.approveRegulator('Climate Change Committee', 'UK', accounts[1], { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT,
            "Only Governing Body (owner) is allowed to do this."
        );
        // add regulator using the correct account
        await regulatorInstance.approveRegulator('Climate Change Committee', 'UK', accounts[1], { from: accounts[0] })
    })


    it("Once a Regulator (accounts[1]) has been added, trying to add it again fails", async () => {

        await truffleAssert.fails(
            regulatorInstance.approveRegulator('Climate Change Committee', 'UK', accounts[1], { from: accounts[0] }),
            truffleAssert.ErrorType.REVERT,
            "Regulator is already authorised!"
        );
    })


    it("Only a Regulator (accounts[1]) is able to add a Company (accounts[2]). Using other accounts (accounts[3]) fails", async () => {

        console.log("Testing adding of Company by Regulator")
        await truffleAssert.fails(
            companyInstance.approveCompany('Apple Inc.', accounts[2], { from: accounts[3] }),
            truffleAssert.ErrorType.REVERT,
            'Only approved regulators are allowed to do this.'
        );
        // add company using the correct account
        await companyInstance.approveCompany('Apple Inc', accounts[2], { from: accounts[1] })

    })


    it("Once a Company (accounts[2]) has been added, adding it again fails", async () => {

        await truffleAssert.fails(
            companyInstance.approveCompany('Apple Inc.', accounts[2], { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT,
            'Address is already an approved Company!'
        );
    })

    it("Only a Regulator (accounts[1]) can update the Company (accounts[2]) yearly limit. Using other accounts (accounts[3]) fails", async () => {
        console.log("Testing updating of Company (accounts[2]) emission limits and subsequent issuing of tokens.");
        await truffleAssert.fails(
            companyInstance.updateYearlyLimit(accounts[2], 2022, 50, { from: accounts[3] }),
            truffleAssert.ErrorType.REVERT,
            'Only approved regulators are allowed to do this.'
        );
        // update yearly limit using the correct account 
        await companyInstance.updateYearlyLimit(accounts[2], 2022, 50, { from: accounts[1] });

    })

    it("Only a Regulator (accounts[1]) can carry out the yearly issuing of tokens to the Company (accounts[2]) based on their emission limit. Using other accounts (accounts[3]) fails", async () => {
        await truffleAssert.fails(
            carbonTokenInstance.mintForYear(accounts[2], 2022, { from: accounts[3] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised as a Regulator!'
        );
        //mint tokens using the correct account
        await carbonTokenInstance.mintForYear(accounts[2], 2022, { from: accounts[1] });

    })



    it("Only the Regulator (accounts[1]) can remove a Company (accounts[2]). Using other accounts (accounts[3]) fails", async () => {

        console.log("Testing removal of Company by Regulator")
        await truffleAssert.fails(
            companyInstance.removeCompany(accounts[2], { from: accounts[3] }),
            truffleAssert.ErrorType.REVERT,
            'Only approved regulators are allowed to do this.'
        );
    })

    it("If the Company (accounts[4]) isn't approved, it cannot be removed", async () => {

        await truffleAssert.fails(
            companyInstance.removeCompany(accounts[4], { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT,
            'Address is not an approved company!'
        );
    })


    it("Only the governing body (accounts[0]) can remove a Regulator (accounts[1]). Using other accounts (accounts[3]) fails", async () => {

        console.log("Testing removal of Regulator by the governing body")
        await truffleAssert.fails(
            regulatorInstance.removeRegulator(accounts[1], { from: accounts[3] }),
            truffleAssert.ErrorType.REVERT,
            "Only Governing Body (owner) is allowed to do this."
        );
    })

    it("If the Regulator (accounts[4]) isn't approved, it cannot be removed", async () => {

        await truffleAssert.fails(
            regulatorInstance.removeRegulator(accounts[4], { from: accounts[0] }),
            truffleAssert.ErrorType.REVERT,
            'Address is not an authorised regulator!'
        );
    })
});

contract("Testing Projects Security", function (accounts) {
    before(async () => {
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

    it("Adding a regulator (accounts[1])", async () => {
        await regulatorInstance.approveRegulator('Climate Change Committee', 'UK', accounts[1], { from: accounts[0] })
        let auth = await regulatorInstance.isApproved(accounts[1])
        assert.strictEqual(
            auth,
            true,
            "Account not added successfully"
        )

    })

    it('Adding a company (accounts[2])', async () => {
        await companyInstance.approveCompany('Apple Inc', accounts[2], { from: accounts[1] })

        //check that account 2 is authorised 
        let auth = await companyInstance.isApproved(accounts[2])
        assert.strictEqual(
            auth,
            true,
            "Account not added successfully"
        )
    })

    it('Only a Company (accounts[2]) can request a project to be approved. Using other accounts (accounts[3]) fails', async () => {
        console.log("Requesting of projects");
        await truffleAssert.fails(
            projectInstance.requestProject('eco-friendly machines', { from: accounts[3] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised Company!'
        );
        // request 2 projects using the correct account 
        let r1 = await projectInstance.requestProject("eco-friendly machines", { from: accounts[2] });
        truffleAssert.eventEmitted(r1, "projectRequested", (ev) => {
            return ev.requester == accounts[2] && ev.projectName == 'eco-friendly machines' && ev.projId == 0
        });

        let r2 = await projectInstance.requestProject("carbon-efficient reactor", { from: accounts[2] });
        truffleAssert.eventEmitted(r2, "projectRequested", (ev) => {
            return ev.requester == accounts[2] && ev.projectName == 'carbon-efficient reactor' && ev.projId == 1
        });


    })


    it("Only a Regulator (accounts[1]) can reject a project. Using other accounts (accounts[3]) fails.", async () => {
        console.log("Rejection of projects");
        await truffleAssert.fails(
            projectInstance.rejectProject('1', { from: accounts[3] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised Regulator!'
        );
    })

    it("Only a Regulator (accounts[1]) can approve a project. Using other accounts (accounts[3]) fails", async () => {
        console.log("Approvals of projects");
        await truffleAssert.fails(
            projectInstance.approveProject('0', 5, { from: accounts[3] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised Regulator!'
        );
    })


    it("Only the Regulator (accounts[1]) is able to award tokens. Using other accounts (accounts[3]) fails", async () => {
        console.log("Awarding of tokens to Company after approval of project");
        await truffleAssert.fails(
            carbonTokenInstance.mintForProject('0', { from: accounts[3] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised as a Regulator!'
        );
    })
});

contract("Testing Emissions Reporting Security", function (accounts) {
    before(async () => {
        userDataStorageInstance = await UserDataStorage.deployed();
        regulatorInstance = await Regulator.deployed();
        companyInstance = await Company.deployed();
        carbonTokenInstance = await CarbonToken.deployed();
    });


    it("Setting Address of Company and Regulator in UserDataStorage", async () => {
        console.log("Initializing Preconditions")
        let s1 = await userDataStorageInstance.setCompanyContract(companyInstance.address);
        truffleAssert.eventEmitted(s1, 'CompanyAddressSet');

        let s2 = await userDataStorageInstance.setRegulatorContract(regulatorInstance.address);
        truffleAssert.eventEmitted(s2, 'RegulatorAddressSet');

    })


    it("Adding a regulator (accounts[1])", async () => {
        await regulatorInstance.approveRegulator('Climate Change Committee', 'UK', accounts[1], { from: accounts[0] })
        let auth = await regulatorInstance.isApproved(accounts[1])
        assert.strictEqual(
            auth,
            true,
            "Account not added successfully"
        )

    })

    it('Adding two companies (accounts[2,3])', async () => {
        await companyInstance.approveCompany('Apple Inc', accounts[2], { from: accounts[1] });
        await companyInstance.approveCompany('Shell', accounts[3], { from: accounts[1] });
        //check that account 2 is authorised 
        let auth1 = await companyInstance.isApproved(accounts[2])
        assert.strictEqual(
            auth1,
            true,
            "Account not added successfully"
        )
        //check that account 3 is authorised
        let auth2 = await companyInstance.isApproved(accounts[3])
        assert.strictEqual(
            auth2,
            true,
            "Account not added successfully"
        )

    })

    it('Only Regulator (accounts[1]) can update the emissions for a Company (accounts[2,3]). Using other accounts (accounts[3]) fails', async () => {
        console.log("Reporting of emissions");
        await truffleAssert.fails(
            companyInstance.reportEmissions(accounts[2], 2022, 25, { from: accounts[3] }),
            truffleAssert.ErrorType.REVERT,
            'Only approved regulators are allowed to do this.'
        );
    })

    it('Regulator (accounts[1]) can only update emissions for an approved Company (accounts[2,3]). Updating for other addresses (accounts[4]) fails.', async () => {
        await truffleAssert.fails(
            companyInstance.reportEmissions(accounts[4], 2022, 25, { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT,
            'Address is not an approved company!'
        );
    })

    it("Only a Regulator (accounts[1]) can burn tokens. Using other accounts (accounts[3]) fails", async () => {
        console.log("Burning of tokens when spent");
        await truffleAssert.fails(
            carbonTokenInstance.destroyTokens(accounts[2], 0, { from: accounts[3] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised as a Regulator!'
        );
    })

    it("Cannot burn more tokens than the company has", async () => {
        await truffleAssert.fails(
            carbonTokenInstance.destroyTokens(accounts[2], 100, { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT,
            "From doesn't have enough balance"
        )
    })
});

contract("Testing Carbon Exchange Security", function (accounts) {
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

    it("Only an approved company can deposit tokens in Wallet. Using all other accounts (accounts[7]) should fail", async() => {
        console.log("Depositing of tokens in Wallet");
        await truffleAssert.fails(
            carbonExchangeInstance.depositToken(10, {from:accounts[7] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised company!'
        )
    })

    it("Only an approved company can withdraw tokens from Wallet. Using other accounts (accounts[7]) should fail", async() => {
        console.log("Withdrawal of tokens from Wallet");
        await truffleAssert.fails(
            carbonExchangeInstance.withdrawToken({from:accounts[7] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised company!'
        )

    })

    it("Only an approved company can place a bid order. Using other accounts (accounts[7]) should fail", async() => {
        console.log("Placing of bid order");
        await truffleAssert.fails(
            carbonExchangeInstance.placeBidOrder(10, 10, {from:accounts[7] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised company!'
        )

    })

    it("Only an approved company can place an ask order. Using other accounts (accounts[7]) should fail", async() => {
        console.log("Placing of ask order");
        await truffleAssert.fails(
            carbonExchangeInstance.placeAskOrder(10, 10, {from:accounts[7] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised company!'
        )

    })

    it("Only an approved company can remove an ask order. Using other accounts (accounts[7]) should fail", async() => {
        console.log("Removal of ask order");
        await truffleAssert.fails(
            carbonExchangeInstance.removeAskOrder(10, {from:accounts[7] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised company!'
        )

    })

    it("Only an approved company can withdraw ETH from Wallet. Using other accounts (accounts[7]) should fail", async() => {
        console.log("Withdrawal of ETH from Wallet");
        await truffleAssert.fails(
            carbonExchangeInstance.withdrawEth({from:accounts[7] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised company!'
        )

    })

contract("Testing Wallet Security", function (accounts) {
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

    it("Carbon exchange address in Wallet can only be set by the owner (accounts[0]). Using other addresses (accounts[2]) fails.", async() => {
        console.log("Setting of carbon exchange address");
        await truffleAssert.fails(
            walletInstance.setCarbonExchangeAddress(accounts[7], {from:accounts[7] }),
            truffleAssert.ErrorType.REVERT,
            'Not owner of contract!'
        );
    })

    it("Deposit ETH function can only be called via the carbon exchange contract that was set. Using other addresses (accounts[2]) fails", async() => {
        console.log("Deposit / Withdraw Transfer of ETH in wallet")
        await truffleAssert.fails(
            walletInstance.depositEth(accounts[2], 10, {from:accounts[2] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised address!'
        );

    })

    it("Withdraw ETH function can only be called via the carbon exchange contract that was set. Using other addresses (accounts[2]) fails", async() => {
        await truffleAssert.fails(
            walletInstance.withdrawEth(accounts[2], {from:accounts[2] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised address!'
        );

    })

    it("Transfer ETH function can only be called via the carbon exchange contract that was set. Using other addresses (accounts[2]) fails", async() => {
        await truffleAssert.fails(
            walletInstance.transferEth(accounts[2], accounts[7], 10, {from:accounts[2] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised address!'
        );

    })

    it("Adding of locked ETH into wallet function can only be called via the carbon exchange contract that was set. Using other addresses (accounts[2]) fails", async() => {
        console.log("Add / reduction of locked ETH in wallet");
        await truffleAssert.fails(
            walletInstance.addLockedEth(accounts[2], 10, {from:accounts[2] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised address!'
        );

    })

    it("Reduction of locked ETH into wallet function can only be called via the carbon exchange contract that was set. Using other addresses (accounts[2]) fails", async() => {
        await truffleAssert.fails(
            walletInstance.reduceLockedEth(accounts[2], 10, {from:accounts[2] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised address!'
        );

    })

    it("Depositing of tokens into wallet function can only be called via the carbon exchange contract that was set. Using other addresses (accounts[2]) fails", async() => {
        console.log("Deposit / withdraw / transfer of tokens in wallet");
        await truffleAssert.fails(
            walletInstance.depositTokens(accounts[2], 10, {from:accounts[2] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised address!'
        );

    })

    it("Withdrawing of tokens out of wallet function can only be called via the carbon exchange contract that was set. Using other addresses (accounts[2]) fails", async() => {
        await truffleAssert.fails(
            walletInstance.withdrawTokens(accounts[2], {from:accounts[2] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised address!'
        );

    })

    it("Transfer of tokens function can only be called via the carbon exchange contract that was set. Using other addresses (accounts[2]) fails", async() => {
        await truffleAssert.fails(
            walletInstance.transferToken(accounts[2], accounts[7], 10, {from:accounts[2] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised address!'
        );

    })

    it("Adding of locked tokens into wallet function can only be called via the carbon exchange contract that was set. Using other addresses (accounts[2]) fails", async() => {
        console.log("Adding / reduction of locked tokens in wallet")
        await truffleAssert.fails(
            walletInstance.addLockedToken(accounts[2], 10, {from:accounts[2] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised address!'
        );

    })

    it("Reduction of locked tokens into wallet function can only be called via the carbon exchange contract that was set. Using other addresses (accounts[2]) fails", async() => {
        await truffleAssert.fails(
            walletInstance.reduceLockedEth(accounts[2], 10, {from:accounts[2] }),
            truffleAssert.ErrorType.REVERT,
            'Not authorised address!'
        );

    })

})





















    

});










