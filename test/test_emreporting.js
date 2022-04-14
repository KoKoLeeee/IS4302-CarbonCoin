const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require('truffle-assertions');
var assert = require('assert');


const Regulator = artifacts.require("Regulator");
const UserDataStorage = artifacts.require("UserDataStorage");
const Company = artifacts.require("Company");
const CarbonToken = artifacts.require("CarbonToken");


contract("Emissions Reporting", function (accounts) {
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

    it("Regulator (accounts[1]) updates 2022 yearly limit for companies[2,3] to be 75 tons and 40 tons respectively.", async () => {
        let e1 = await companyInstance.updateYearlyLimit(accounts[2], 2022, 75, { from: accounts[1] });
        truffleAssert.eventEmitted(e1, "YearlyLimitUpdated");
        let e2 = await companyInstance.updateYearlyLimit(accounts[3], 2022, 40, { from: accounts[1] });
        truffleAssert.eventEmitted(e2, "YearlyLimitUpdated");
    })


    it("Regulator (accounts[1]) issues 75 tokens to Exxon Mobil (accounts[2]) and 40 tokens to Shell (accounts[3]) based on their 2022 limit", async () => {
        let i1 = await carbonTokenInstance.mintForYear(accounts[2], 2022, { from: accounts[1] });
        truffleAssert.eventEmitted(i1, "mintedForYear");
        let i2 = await carbonTokenInstance.mintForYear(accounts[3], 2022, { from: accounts[1] });
        truffleAssert.eventEmitted(i2, "mintedForYear");
    })

    it("Regulator (accounts[1]) reports emissions for Exxon Mobil and Shell(accounts[2,3]) to be 50 tons each for 2022", async () => {
        console.log("Reporting of emissions");
        let r1 = await companyInstance.reportEmissions(accounts[2], 2022, 50, { from: accounts[1] });
        truffleAssert.eventEmitted(r1, 'EmissionsReported', (ev) => {
            return ev.year == 2022 && ev.emissions == 50
        })
        let r2 = await companyInstance.reportEmissions(accounts[3], 2022, 50, { from: accounts[1] });
        truffleAssert.eventEmitted(r2, 'EmissionsReported', (ev) => {
            return ev.year == 2022 && ev.emissions ==50
        })

    })

    it("Both Exxon Mobil and Shell (accounts[2,3]) emissions should reflect 50 tons for 2022", async () => {
        //Exxon Mobil
        let a1 = await companyInstance.getEmission(accounts[2], 2022);
        assert.strictEqual(
            a1.toString(),
            '50',
            "Emissions not updated"
        )
        //Shell
        let a2 = await companyInstance.getEmission(accounts[3], 2022);
        assert.strictEqual(
            a1.toString(),
            '50',
            "Emissions not updated"
        )

    })

    it("Regulator (accounts[1]) burns 50 tokens belonging to Exxon Mobil (accounts[2])", async () => {
        console.log("Burning of tokens when spent");
        let b1 = await carbonTokenInstance.destroyTokens(accounts[2], 50, { from: accounts[1] });
        truffleAssert.eventEmitted(b1, "TokensDestroyed");
    })


    //computation of how many tokens to burn is done in the frontend.
    //Shell emitted 50 tons but only has 40 tokens. So we burn 40 tokens and fine them for the other 10 tons.
    it("Since Shell emitted more than the tokens they have, Regulator (accounts[1]) burns all (40) tokens belonging to Shell (accounts[3]). Shell will be fined for the excess 10 tons. ", async () => {
        let b1 = await carbonTokenInstance.destroyTokens(accounts[3], 40, { from: accounts[1] });
        truffleAssert.eventEmitted(b1, "TokensDestroyed");
    })

    it("Exxon Mobil (accounts[2]) token balance should fall by the amount that was burnt, left 75-50=25 tokens", async () => {
        let a1 = await carbonTokenInstance.getTokenBalance(accounts[2]);
        assert.strictEqual(
            a1.toString(),
            '25',
            "Tokens not burnt successfully"
        )
    })

    it("Shell (accounts[3]) token balance should fall by the amount that was burnt, left 40-40=0 tokens", async () => {
        let a1 = await carbonTokenInstance.getTokenBalance(accounts[3]);
        assert.strictEqual(
            a1.toString(),
            '0',
            "Tokens not burned successfully"
        )
    })
});
