pragma solidity ^0.5.0;

import "./UserDataStorage.sol";

contract Company {
    address owner;
    UserDataStorage dataStorage;

    constructor() public {
        owner = msg.sender;
    }

    // modifiers

    // Restrict access to owner of contract only
    modifier ownerOnly() {
        require(msg.sender == owner, 'Only Governing Body (owner) is allowed to do this!');
        _;
    }

    // restrict access to only authorised regulators.
    modifier authorisedRegulatorOnly() {
        require(dataStorage.isAuthorisedRegulator(msg.sender), 'Only approved regulators are allowed to do this.');
        _;
    }

    // setter for UserDataStorage
    function setUserDataStorageAddress(address _address) public ownerOnly {
        dataStorage = UserDataStorage(_address);
    }

    // For Regulators to authorised companies
    function approveCompany(string memory name, address toApprove) public authorisedRegulatorOnly {
        // Update UserDataStorage
        dataStorage.addCompany(name, toApprove, msg.sender);
    }

    // For regulators to forcefully remove companies
    function removeCompany(address toRemove) public authorisedRegulatorOnly {
        dataStorage.removeCompany(toRemove);
    }

    // For Regulators to report emissions of companies
    function reportEmissions(address company, uint256 year, uint256 emissions) public authorisedRegulatorOnly {
        dataStorage.updateCompanyEmissions(company, year, emissions);
    }

    // getter functions

    // check if an adress is an authorised company
    function isAuthorised(address _address) public view returns(bool) {
        return dataStorage.isApprovedCompany(_address);
    }

}