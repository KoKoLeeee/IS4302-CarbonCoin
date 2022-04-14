pragma solidity ^0.5.0;

import "./UserDataStorage.sol";

contract Company {
    // owner of the contract (governing body)
    address owner;
    // UserDataStorage instance that is holding the data of the CompanyInformation
    UserDataStorage dataStorage;

    // events
    event ApprovedCompany(address);
    event RemovedCompany(address);
    event YearlyLimitUpdated(address, uint256, uint256);
    event EmissionsReported(uint256 year, uint256 emissions);

    constructor(UserDataStorage dataStorageAddress) public {
        owner = msg.sender;
        dataStorage = dataStorageAddress;
    }

    // ------ modifiers ------

    // Restrict access to owner of contract only
    modifier ownerOnly() {
        require(msg.sender == owner, 'Only Governing Body (owner) is allowed to do this!');
        _;
    }

    // restrict access to only approved regulators.
    modifier approvedRegulatorOnly() {
        require(dataStorage.isApprovedRegulator(msg.sender), 'Only approved regulators are allowed to do this.');
        _;
    }

    // ----- Setter -----

    // setter for UserDataStorage
    function setUserDataStorageAddress(address _address) public ownerOnly {
        dataStorage = UserDataStorage(_address);
    }

    // ----- Class Functions -----

    // For Regulators to authorised companies
    function approveCompany(string memory name, address toApprove) public approvedRegulatorOnly {
        // Update UserDataStorage
        dataStorage.addCompany(name, toApprove, msg.sender);
        emit ApprovedCompany(toApprove);
    }

    // For regulators to forcefully remove companies
    function removeCompany(address toRemove) public approvedRegulatorOnly {
        dataStorage.removeCompany(toRemove);
        emit RemovedCompany(toRemove);
    }

    // For Regulators to report emissions of companies
    function reportEmissions(address company, uint256 year, uint256 emissions) public approvedRegulatorOnly {
        dataStorage.updateCompanyEmissions(company, year, emissions);
        emit EmissionsReported(year, emissions);
    }

    // For regulators to update yearly emission limit for companies
    function updateYearlyLimit(address company, uint256 year, uint256 limit) public approvedRegulatorOnly {
        dataStorage.updateCompanyLimits(company, year, limit);
        emit YearlyLimitUpdated(company, year, limit);
    }
    // ----- Getters -----

    // check if an adress is an authorised company
    function isApproved(address _address) public view returns(bool) {
        return dataStorage.isApprovedCompany(_address);
    }

    // get emissions for specific year
    function getEmission(address _address, uint256 year) public view returns (uint256) {
        return dataStorage.getEmissions(_address, year);
    }

    // get yearly emission limit of company
    function getYearLimit(address _address, uint256 year) public view returns (uint256) {
        return dataStorage.getLimit(_address, year);
    }


}