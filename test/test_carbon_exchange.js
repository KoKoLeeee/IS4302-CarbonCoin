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

    // Initializing Preconditions to test Carbon Exchange Market

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

    it("Setting Address of CarbonExchange in Wallet", async () => {
        let s4 = await walletInstance.setCarbonExchangeAddress(carbonExchangeInstance.address);
        truffleAssert.eventEmitted(s4, 'CarbonExchangeAddressSet');
    })

    it("Setting Address of CarbonExchange in CarbonToken", async () => {
        let s5 = await carbonTokenInstance.setCarbonExchangeAddress(carbonExchangeInstance.address);
        truffleAssert.eventEmitted(s5, 'CarbonExchangeAddressSet');
    })

    it("Setting Address of CarbonExchange in TransactionData", async () => {
        let s6 = await transactionDataInstance.setCarbonExchangeAddress(carbonExchangeInstance.address);
        truffleAssert.eventEmitted(s6, 'CarbonExchangeAddressSet');
    })

    it("Approving accounts[1] as a Regulator", async () => {
        let s7 = await regulatorInstance.approveRegulator("Regulator 1", "Singapore", accounts[1], {from: accounts[0]});
        truffleAssert.eventEmitted(s7, 'ApprovedRegulator');
    })

    it("Approving accounts[2,3] (Company S1 and S2) as Sellers and accounts[4,5] (Company B1 and B2) as Buyers", async () => {
        let s8 = await companyInstance.approveCompany("Company S1", accounts[2], {from:accounts[1]});
        let s9 = await companyInstance.approveCompany("Company S2", accounts[3], {from:accounts[1]});
        let s10 = await companyInstance.approveCompany("Company B1", accounts[4], {from:accounts[1]});
        let s11 = await companyInstance.approveCompany("Company B2", accounts[5], {from:accounts[1]});
        
        truffleAssert.eventEmitted(s8, 'ApprovedCompany');
        truffleAssert.eventEmitted(s9, 'ApprovedCompany');
        truffleAssert.eventEmitted(s10, 'ApprovedCompany');
        truffleAssert.eventEmitted(s11, 'ApprovedCompany');
    })

    it("Adminstratively mint 100 tokens for both accounts[2,3] (Company S1 and S2)", async () => {
        let s12 = await carbonTokenInstance.mint(accounts[2], 100, {from: accounts[0]});
        let s13 = await carbonTokenInstance.mint(accounts[3], 100, {from: accounts[0]});
        truffleAssert.eventEmitted(s12, 'OwnerMint', (ev) => {
            return ev._to == accounts[2] && ev.amount == 100;
        });

        truffleAssert.eventEmitted(s13, 'OwnerMint', (ev) => {
            return ev._to == accounts[3] && ev.amount == 100;
        })
         
    })

    // Begin Testing for Carbon Exchange Contract

    it("B1 places a Bid Order for 100 tokens at 0.01Eth without Depositing Eth", async () => {
        console.log("Testing Carbon Exchange Contract");
        await truffleAssert.fails(
            carbonExchangeInstance.placeBidOrder(100, 10000000000000000n, {from:accounts[4]}),
            truffleAssert.ErrorType.REVERT,
            "Insufficient funds! Please top up!"
        );
        
    });

    it("B1 places a Bid Order for 100 tokens at 0.01Eth", async () => {
        let bid1 = await carbonExchangeInstance.placeBidOrder(100, 10000000000000000n, {from:accounts[4], value: 1E18});

        truffleAssert.eventEmitted(bid1, 'DepositEth', (ev) => {
            return ev._address == accounts[4] && ev.amount == 1000000000000000000n;
        }, 'Incorrect DepositEth parameters');
        
        truffleAssert.eventEmitted(bid1, 'WalletLockEth', (ev) => {
            return ev._address == accounts[4] && ev.amount == 100n * 10000000000000000n;
        });

        truffleAssert.eventNotEmitted(bid1, 'WalletUnlockEth');
        truffleAssert.eventNotEmitted(bid1, 'WalletTransferEth');
        truffleAssert.eventNotEmitted(bid1, 'WalletUnlockToken');
        truffleAssert.eventNotEmitted(bid1, 'WalletTransferToken');

        truffleAssert.eventEmitted(bid1, 'PlacedBidOrder', (ev) => {
            return ev._address == accounts[4] && ev.amount == 100 && ev.price == 10000000000000000n;
        });
        
    });

    it("S1 cannot place an Ask order without Depositing tokens", async () => {
        await truffleAssert.fails(
            carbonExchangeInstance.placeAskOrder(50, 10000000000000000n, {from: accounts[2]}),
            truffleAssert.ErrorType.REVERT,
            'Insufficient Tokens to sell!'
        );
    });

    it("S1 deposits 100 tokens to the Exchange", async () => {
        let deposit1 = await carbonExchangeInstance.depositToken(100, {from: accounts[2]});
        truffleAssert.eventEmitted(deposit1, 'DepositToken', (ev) => {
            return ev._address == accounts[2] && ev.amount == 100;
        })
    });

    it("S1 places an Ask Order for 50 tokens at 0.01Eth", async () => {
        let ask1 = await carbonExchangeInstance.placeAskOrder(50, 10000000000000000n, {from: accounts[2]});
        
        truffleAssert.eventEmitted(ask1, 'WalletLockToken', (ev) => {
            return ev._address == accounts[2] && ev.amount == 50;
        })

        truffleAssert.eventEmitted(ask1, 'WalletUnlockEth', (ev) => {
            return ev._address == accounts[4] && ev.amount == 50n * 10000000000000000n;
        })

        truffleAssert.eventEmitted(ask1, 'WalletTransferEth', (ev) => {
            return ev._from == accounts[4] && ev._to == accounts[2] && ev.amount == 50n * 10000000000000000n; 
        })

        truffleAssert.eventEmitted(ask1, 'WalletUnlockToken', (ev) => {
            return ev._address == accounts[2] && ev.amount == 50;
        })

        truffleAssert.eventEmitted(ask1, 'WalletTransferToken', (ev) => {
            return ev._from == accounts[2] && ev._to == accounts[4] && ev.amount == 50;
        })

        truffleAssert.eventEmitted(ask1, 'FilledAskOrder', (ev) => {
            return ev._address == accounts[2] && ev.amount == 50 && ev.price == 10000000000000000n;
        })

        truffleAssert.eventEmitted(ask1, 'FilledBidOrder', (ev) => {
            return ev._address == accounts[4] && ev.amount == 50 && ev.price == 10000000000000000n;
        })

    });

    it("S1 places an Ask Order for 50 tokens at 0.02Eth", async () => {
        let ask2 = await carbonExchangeInstance.placeAskOrder(50, 20000000000000000n, {from: accounts[2]});
        
        // truffleAssert.eventEmitted(ask2, 'DepositToken');
        truffleAssert.eventEmitted(ask2, 'WalletLockToken', (ev) => {
            return ev._address == accounts[2] && ev.amount == 50;
        })

        truffleAssert.eventEmitted(ask2, 'PlacedAskOrder', (ev) => {
            return ev._address == accounts[2] && ev.amount == 50 && ev.price == 20000000000000000n;
        })
    });

    it("S2 deposits 100 tokens to the Exchange", async () => {
        let deposit2 = await carbonExchangeInstance.depositToken(100, {from: accounts[3]});
        truffleAssert.eventEmitted(deposit2, 'DepositToken', (ev) => {
            return ev._address == accounts[3] && ev.amount == 100;
        })
    });

    it("S2 places an Ask Order for 100 tokens at 0.01Eth", async () => {
        let ask3 = await carbonExchangeInstance.placeAskOrder(100, 10000000000000000n, {from: accounts[3]});

        // truffleAssert.eventEmitted(ask3, 'DepositToken');
        truffleAssert.eventEmitted(ask3, 'WalletLockToken', (ev) => {
            return ev._address == accounts[3] && ev.amount == 100;
        })

        truffleAssert.eventEmitted(ask3, 'WalletUnlockEth', (ev) => {
            return ev._address == accounts[4] && ev.amount == 50n * 10000000000000000n;
        })

        truffleAssert.eventEmitted(ask3, 'WalletTransferEth', (ev) => {
            return ev._from == accounts[4] && ev._to == accounts[3] && ev.amount == 50n * 10000000000000000n; 
        })

        truffleAssert.eventEmitted(ask3, 'WalletUnlockToken', (ev) => {
            return ev._address == accounts[3] && ev.amount == 50;
        })

        truffleAssert.eventEmitted(ask3, 'WalletTransferToken', (ev) => {
            return ev._from == accounts[3] && ev._to == accounts[4] && ev.amount == 50;
        })

        truffleAssert.eventEmitted(ask3, 'FilledAskOrder', (ev) => {
            return ev._address == accounts[3] && ev.amount == 50 && ev.price == 10000000000000000n;
        })

        truffleAssert.eventEmitted(ask3, 'FilledBidOrder', (ev) => {
            return ev._address == accounts[4] && ev.amount == 50 && ev.price == 10000000000000000n;
        })


        truffleAssert.eventEmitted(ask3, 'PlacedAskOrder', (ev) => {
            return ev._address == accounts[3] && ev.amount == 50 && ev.price == 10000000000000000n;
        })
    });

    it("B2 places a Bid Order for 50 tokens at 0.02Eth", async () => {
        let bid2 = await carbonExchangeInstance.placeBidOrder(50, 20000000000000000n, {from: accounts[5], value: 2E18})
        
        truffleAssert.eventEmitted(bid2, 'DepositEth', (ev) => {
            return ev._address == accounts[5] && ev.amount == 2000000000000000000n;
        });

        truffleAssert.eventEmitted(bid2, 'WalletLockEth', (ev) => {
            return ev._address == accounts[5] && ev.amount == 50n * 20000000000000000n;
        })

        truffleAssert.eventEmitted(bid2, 'WalletUnlockEth', (ev) => {
            return ev._address == accounts[5] && ev.amount == 50n * 20000000000000000n;
        })

        truffleAssert.eventEmitted(bid2, 'WalletTransferEth', (ev) => {
            return ev._from == accounts[5] && ev._to == accounts[3] && ev.amount == 50n * 10000000000000000n;
        })

        truffleAssert.eventEmitted(bid2, 'WalletUnlockToken', (ev) => {
            return ev._address == accounts[3] && ev.amount == 50; 
        })

        truffleAssert.eventEmitted(bid2, 'WalletTransferToken', (ev) => {
            return ev._from == accounts[3] && ev._to == accounts[5] && ev.amount == 50;
        })

        truffleAssert.eventEmitted(bid2, 'FilledAskOrder', (ev) => {
            return ev._address == accounts[3] && ev.amount == 50 && ev.price == 10000000000000000n;
        })

        truffleAssert.eventEmitted(bid2, 'FilledBidOrder', (ev) => {
            return ev._address == accounts[5] && ev.amount == 50 && ev.price == 10000000000000000n;
        })

    })
    
    it("B2 places a Bid Order for 50 tokens at 0.02Eth AGAIN", async () => {
        let bid3 = await carbonExchangeInstance.placeBidOrder(50, 20000000000000000n, {from: accounts[5]})
        
        truffleAssert.eventNotEmitted(bid3, 'DepositEth');
        
        truffleAssert.eventEmitted(bid3, 'WalletLockEth', (ev) => {
            return ev._address == accounts[5] && ev.amount == 50n * 20000000000000000n;
        })

        truffleAssert.eventEmitted(bid3, 'WalletUnlockEth', (ev) => {
            return ev._address == accounts[5] && ev.amount == 50n * 20000000000000000n;
        })

        truffleAssert.eventEmitted(bid3, 'WalletTransferEth', (ev) => {
            return ev._from == accounts[5] && ev._to == accounts[2] && ev.amount == 50n * 20000000000000000n;
        })

        truffleAssert.eventEmitted(bid3, 'WalletUnlockToken', (ev) => {
            return ev._address == accounts[2] && ev.amount == 50; 
        })

        truffleAssert.eventEmitted(bid3, 'WalletTransferToken', (ev) => {
            return ev._from == accounts[2] && ev._to == accounts[5] && ev.amount == 50;
        })

        truffleAssert.eventEmitted(bid3, 'FilledAskOrder', (ev) => {
            return ev._address == accounts[2] && ev.amount == 50 && ev.price == 20000000000000000n;
        })

        truffleAssert.eventEmitted(bid3, 'FilledBidOrder', (ev) => {
            return ev._address == accounts[5] && ev.amount == 50 && ev.price == 20000000000000000n;
        })

    })

    it("B1 places an Ask Order of 100 tokens at 0.01Eth, fails to Withdraw his tokens", async () => {
        let ask4 = await carbonExchangeInstance.placeAskOrder(100, 10000000000000000n, {from: accounts[4]});

        truffleAssert.eventEmitted(ask4, 'WalletLockToken', (ev) => {
            return ev._address == accounts[4] && ev.amount == 100;
        })
        truffleAssert.eventEmitted(ask4, 'PlacedAskOrder', (ev) => {
            return ev._address == accounts[4] && ev.amount == 100 && ev.price == 10000000000000000n;
        })

        await truffleAssert.fails(
            carbonExchangeInstance.withdrawToken({from: accounts[4]}),
            truffleAssert.ErrorType.REVERT,
            'No withdrawable Tokens!'
        )

    })

    it("B1 cancels his Ask Order", async () => {
        let cancel_ask1 = await carbonExchangeInstance.removeAskOrder(10000000000000000n, {from: accounts[4]});

        truffleAssert.eventEmitted(cancel_ask1, 'WalletUnlockToken', (ev) => {
            return ev._address == accounts[4] && ev.amount == 100;
        })

        truffleAssert.eventEmitted(cancel_ask1, 'RemovedAskOrder', (ev) => {
            return ev._address == accounts[4] && ev.amount == 100 && ev.price == 10000000000000000n
        })
    })

    it("B1 successfully withdraws his tokens", async () => {
        let withdraw_token1 = await carbonExchangeInstance.withdrawToken({from: accounts[4]});

        truffleAssert.eventEmitted(withdraw_token1, 'WithdrawToken', (ev) => {
            return ev._address == accounts[4] && ev.amount == 100;
        })
    })

    it("S1 places a Bid Order for 50 tokens at 0.01Eth, only can withdraw 1Eth", async () => {
        let bid4 = await carbonExchangeInstance.placeBidOrder(50, 10000000000000000n, {from: accounts[2]});

        truffleAssert.eventEmitted(bid4, 'WalletLockEth', (ev) => {
            return ev._address == accounts[2] && ev.amount == 500000000000000000n;
        })

        truffleAssert.eventEmitted(bid4, 'PlacedBidOrder', (ev) => {
            return ev._address == accounts[2] && ev.amount == 50 && ev.price == 10000000000000000n;
        })

        let withdraw_eth1 = await carbonExchangeInstance.withdrawEth({from: accounts[2]});

        truffleAssert.eventEmitted(withdraw_eth1, 'WithdrawEth', (ev) => {
            return ev._address == accounts[2] && ev.amount == 1000000000000000000n
        })

    })

    it("S1 cancels Bid Order and manage to withdraw remaining 0.5Eth", async() => {
        let cancel_bid1 = await carbonExchangeInstance.removeBidOrder(10000000000000000n, {from: accounts[2]});

        truffleAssert.eventEmitted(cancel_bid1, 'WalletUnlockEth', (ev) => {
            return ev._address == accounts[2] && ev.amount == 50n * 10000000000000000n;
        })

        truffleAssert.eventEmitted(cancel_bid1, 'RemovedBidOrder', (ev) => {
            return ev._address == accounts[2] && ev.amount == 50 && ev.price == 10000000000000000n;
        })

        let withdraw_eth2 = await carbonExchangeInstance.withdrawEth({from: accounts[2]});

        truffleAssert.eventEmitted(withdraw_eth2, 'WithdrawEth', (ev) => {
            return ev._address == accounts[2] && ev.amount == 500000000000000000n;
        })
    })

    it("B1 fails to withdraw Eth from account", async () => {
        await truffleAssert.fails(
            carbonExchangeInstance.withdrawEth({from: accounts[4]}),
            truffleAssert.ErrorType.REVERT,
            'No withdrawable Eth!'
        )
    })

    it("S1 fails to withdraw Tokens from account", async () => {
        await truffleAssert.fails(
            carbonExchangeInstance.withdrawToken({from: accounts[2]}),
            truffleAssert.ErrorType.REVERT,
            'No withdrawable Tokens!'
        );
    })

});
