pragma solidity ^0.5.0;

//Data segregation for company and regulator profiles 
contract UserDataStorage {
    
    struct RegulatorInformation {
        string name;
        string country;
    }

    struct CompanyInformation {
        string name;
        address approvedBy;
        // maps year to emissions of company for that year
        mapping(uint256 => uint256) emissions;
        // maps year to emission limit of company set by Regulators
        mapping(uint256 => uint256) limits;
    }

    // address of owner (governing body)
    address owner;

    // addresses of regulator and company contract 
    // (ensures that only these contracts are able to make changes to data storage)
    address regulatorContract;
    address companyContract;

    // mapping of addresses to regulator and company information
    mapping(address => RegulatorInformation) regulators;
    mapping(address => CompanyInformation) public companies;

    // events
    event CompanyAddressSet(address);
    event RegulatorAddressSet(address);

    constructor() public {
        owner = msg.sender;
    }

    // ----- modifiers -----

    // Restrict access to owner of contract only
    modifier ownerOnly() {
        require(msg.sender == owner, 'Only the owner can set the regulator/contract address');
        _;
    }
    
    // Restrict access to regulatorContract address set by the owner
    modifier approvedRegulatorContractOnly() {
        require(msg.sender == regulatorContract, 'Unauthorised address!');
        _;
    }

    // Restrict access to companyContract address set by the owner
    modifier approvedCompanyContractOnly() {
        require(msg.sender == companyContract, 'Unathorised address!');
        _;
    }

    // ----- setters -----

    // to set the companyContract address that can make modifications to data storage
    function setCompanyContract(address _address) public ownerOnly {
        companyContract = _address;
        emit CompanyAddressSet(_address);
    }

    // to set the regulatorContract address that can make modifications to data storage
    function setRegulatorContract(address _address) public ownerOnly {
        regulatorContract = _address;
        emit RegulatorAddressSet(_address);
    }

    // ------ Regulator Functions ------

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

    // --- Getter functions ---

    // true if regulator is approved
    function isApprovedRegulator(address _address) public view returns(bool) {
        return bytes(regulators[_address].name).length != 0;
    }


    // ------ Company functions ------

    // add company to approved company list
    function addCompany(string memory name, address company, address approvedBy) public approvedCompanyContractOnly {
        //ensure that address is not already an approved company
        require(bytes(companies[company].name).length == 0, 'Address is already an approved Company!');
        companies[company] = CompanyInformation({name: name, approvedBy: approvedBy});
    }

    // remove company from approved company list
    function removeCompany(address company) public approvedCompanyContractOnly {
        // ensure that address is an approved company
        require(bytes(companies[company].name).length != 0, 'Address is not an approved company!');

        delete companies[company];
    }

    //  update campany carbon emissions for the year
    function updateCompanyEmissions(address company, uint256 year, uint256 emissions) public approvedCompanyContractOnly {
        // ensure that address is an approved company
        require(bytes(companies[company].name).length != 0, 'Address is not an approved company!');

        companies[company].emissions[year] = emissions;
    }

    // update company emission limits for the year
    function updateCompanyLimits(address company, uint256 year, uint256 limit) public approvedCompanyContractOnly {
        require(bytes(companies[company].name).length != 0, 'Address is not an approved company!');

        companies[company].limits[year] = limit;
    }
    // --- Getter functions ---

    // true if company is approved
    function isApprovedCompany(address _address) public view returns(bool) {
        return bytes(companies[_address].name).length != 0;
    }

    // returns emission in specified year by company address.
    function getEmissions(address _address, uint256 year) public view returns (uint256) {
        return companies[_address].emissions[year];
    }

    // returns emission limit in specified year by company address
    function getLimit(address _address, uint256 year) public view returns (uint256) {
        return companies[_address].limits[year];
    }

}

