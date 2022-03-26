pragma solidity ^0.5.0;

//Data segregation for company and regulator profiles 
contract UserDataStorage {
    address owner;

    struct RegulatorInformation {
        string name;
        bool authorised;
    }

    struct CompanyInformation {
        string name;
        bool authorised;
    }

    constructor(string memory _ownerName) public {
        owner = msg.sender;
        regulators[msg.sender] = RegulatorInformation({name: _ownerName, authorised: true});
    }

    mapping(address => RegulatorInformation) public regulators;
    mapping(address => CompanyInformation) companies;

    function addRegulator(string memory name, address _address, bool authorized) public {
      // if ((regulators[_address].authorised == false) && (keccak256(bytes(regulators[_address].name))) == keccak256(bytes(""))) {
            regulators[_address] = RegulatorInformation({name: name, authorised: authorized});
        //}
    }

    function updateRegulatorAuthorisation(address _address, bool newAuthorisationStatus) public {
        regulators[_address].authorised = newAuthorisationStatus;
    }

    function removeRegulator(address _address) public {
        delete regulators[_address];
    }

    function getRegulatorAuthorisation(address _address) public view returns(bool) {
        return regulators[_address].authorised;
    }

    function addCompany(string memory name, address _address, bool authorized) public {
      // if ((regulators[_address].authorised == false) && (keccak256(bytes(regulators[_address].name))) == keccak256(bytes(""))) {
            companies[_address] = CompanyInformation({name: name, authorised: authorized});
        //}
    }

    function updateCompanyAuthorisation(address _address, bool newAuthorisationStatus) public {
        companies[_address].authorised = newAuthorisationStatus;
    }

    function removeCompany(address _address) public {
        delete companies[_address];
    }

    function getCompanyAuthorisation(address _address) public view returns(bool) {
        return companies[_address].authorised;
    }

}

