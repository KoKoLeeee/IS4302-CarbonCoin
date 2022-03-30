pragma solidity ^0.5.0;

//Data segregation for company and regulator profiles 
contract UserDataStorage {

    enum Status {
        Requested,
        Approved,
        Rejected
    }
    
    struct RegulatorInformation {
        string name;
        Status status;
    }

    struct CompanyInformation {
        string name;
        Status status;
        mapping(uint256 => uint256) emissions;
    }

    address owner;
    address regulatorContract;
    address companyContract;

    mapping(address => RegulatorInformation) regulators;
    mapping(address => CompanyInformation) companies;

    constructor(string memory _ownerName) public {
        owner = msg.sender;
        regulators[msg.sender] = RegulatorInformation({name: _ownerName, status: Status.Approved});
    }

    // access restrictions
    modifier approvedRegulatorContract() {
        require(msg.sender == regulatorContract, 'Unauthorised address!');
        _;
    }

    modifier approvedCompanyContract() {
        require(msg.sender == companyContract, 'Unathorised address!');
        _;
    }

    // Regulator Functions

    function addRegulator(string memory name, address _address, Status _status) public approvedRegulatorContract {
        regulators[_address] = RegulatorInformation({name: name, status: _status});
    }

    function updateRegulatorAuthorisation(address _address, Status _status) public approvedRegulatorContract {
        regulators[_address].status = _status;
    }

    function removeRegulator(address _address) public approvedRegulatorContract {
        delete regulators[_address];
    }

    // Regulator Getter functions
    function getRegulatorStatus(address _address) public view returns(Status) {
        return regulators[_address].status;
    }

    // Company functions


    function addCompany(string memory name, address _address, Status _status) public approvedCompanyContract {
        companies[_address] = CompanyInformation({name: name, status: _status});
    }

    function updateCompanyAuthorisation(address _address, Status _status) public approvedCompanyContract {
        companies[_address].status = _status;
    }

    function removeCompany(address _address) public approvedCompanyContract {
        delete companies[_address];
    }

    function updateCompanyEmissions(address company, uint256 year, uint256 emissions) public approvedCompanyContract {
        companies[company].emissions[year] = emissions;
    }

    function getCompanyStatus(address _address) public view returns(Status) {
        return companies[_address].status;
    }

}

