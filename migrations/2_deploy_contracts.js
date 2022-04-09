const Regulator = artifacts.require("Regulator");
const UserDataStorage = artifacts.require("UserDataStorage");
const Company = artifacts.require("Company");
const ProjectStorage = artifacts.require("ProjectStorage");
const Project = artifacts.require("Project");
const ERC20 = artifacts.require("ERC20");
const CarbonToken = artifacts.require("CarbonToken");
const Wallet = artifacts.require("Wallet");
const TransactionData = artifacts.require("TransactionData");
const CarbonExchange = artifacts.require("CarbonExchange");

module.exports = (deployer, network, accounts) => {
    deployer.deploy(UserDataStorage).then(function() {
<<<<<<< HEAD
        return deployer.deploy(Regulator);
=======
        return deployer.deploy(Regulator, UserDataStorage.address);
>>>>>>> origin/CarbonToken
    }).then(function() {
        return deployer.deploy(Company, UserDataStorage.address);
    }).then(function() {
        return deployer.deploy(ProjectStorage);
    }).then(function () {
        return deployer.deploy(Project, Regulator.address, Company.address, ProjectStorage.address);
    // }).then(function () {
    //     return deployer.deploy(ERC20);
    // }).then(function () {
        return deployer.deploy(CarbonToken, Regulator.address, Company.address, Project.address);
    }).then(function () {
        return deployer.deploy(Wallet)
    }).then(function () {
        return deployer.deploy(TransactionData)
    }).then(function () {
        return deployer.deploy(CarbonExchange, Wallet.address, TransactionData.address, CarbonToken.address, Company.address);
    });
};