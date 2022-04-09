const Regulator = artifacts.require("Regulator");
const UserDataStorage = artifacts.require("UserDataStorage");
const Company = artifacts.require("Company");

module.exports = (deployer, network, accounts) => {
    deployer.deploy(UserDataStorage).then(function() {
        return deployer.deploy(Regulator);
    }).then(function() {
        return deployer.deploy(Company);
    });
};