pragma solidity ^0.5.0;

//Data segregation for company and regulator profiles 
contract UserDataStorage {

    // enum Status {
    //     Requested,
    //     Approved,
    //     Rejected
    // }
    
    struct RegulatorInformation {
        string name;
        string country;
    }

    struct CompanyInformation {
        string name;
        address approvedBy;
        mapping(uint256 => uint256) emissions;
    }

    address owner;
    address regulatorContract;
    address companyContract;

    mapping(address => RegulatorInformation) regulators;
    mapping(address => CompanyInformation) companies;

    constructor() public {
        owner = msg.sender;
    }

    // modifiers
    modifier approvedRegulatorContractOnly() {
        require(msg.sender == regulatorContract, 'Unauthorised address!');
        _;
    }

    modifier approvedCompanyContractOnly() {
        require(msg.sender == companyContract, 'Unathorised address!');
        _;
    }

    // Regulator Functions

    // add regulator to list of authorised regulators
    function addRegulator(string memory name, string memory country, address _address) public approvedRegulatorContractOnly {
        // ensure that regulator has not been authorised yet.
        require(bytes(regulators[_address].name).length == 0, 'Regulator is already authorised!');
        regulators[_address] = RegulatorInformation({name: name, country: country});
    }

    // remove regulators from list of authorised regulators
    function removeRegulator(address _address) public approvedRegulatorContractOnly {
        // Ensure that regulator is authorised.
        require(bytes(regulators[_address].name).length != 0, 'Address is not an authorised regulator!');

        delete regulators[_address];
    }

    // Regulator Getter functions

    // checks if address belongs to an authorised regulator.
    function isAuthorisedRegulator(address _address) public view returns(bool) {
        return bytes(regulators[_address].name).length != 0;
    }

    // Company functions

    // to add company to approved company list
    function addCompany(string memory name, address company, address approvedBy) public approvedCompanyContractOnly {
        //ensure that address is not already an approved company
        require(bytes(companies[company].name).length == 0, 'Address is already an approved Company!');
        companies[company] = CompanyInformation({name: name, approvedBy: approvedBy});
    }

    // to remove company from approved company list
    function removeCompany(address company) public approvedCompanyContractOnly {
        // ensure that address is an approved company
        require(bytes(companies[company].name).length != 0, 'Address is not an approved company!');

        delete companies[company];
    }

    // To update campany carbon emissions for the year
    function updateCompanyEmissions(address company, uint256 year, uint256 emissions) public approvedCompanyContractOnly {
        // ensure that address is an approved company
        require(bytes(companies[company].name).length != 0, 'Address is not an approved company!');

        companies[company].emissions[year] = emissions;
    }

    // checks if address belongs to an approved company.
    function isApprovedCompany(address _address) public view returns(bool) {
        return bytes(companies[_address].name).length != 0;
    }

}

