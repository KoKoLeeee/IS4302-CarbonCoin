pragma solidity ^0.5.0;

import "./UserDataStorage.sol";

contract Regulator {
    address owner;
    UserDataStorage dataStorage;

    constructor() public {
        owner = msg.sender;
    }

    // Access Restriction to only allow owner of contract to call methods.
    modifier ownerOnly() {
        require(msg.sender == owner, "Only Governing Body (owner) is allowed to do this.");
        _;
    }

    // setter for UserDataStorage.
    function setUserDataStorageAddress(address _address) public ownerOnly {
        dataStorage = UserDataStorage(_address);
    }

    // For contract owner to approve Regulators
    function approveRegulator(string memory name, string memory country, address toApprove) public ownerOnly {
        dataStorage.addRegulator(name, country, toApprove);

    }

    // For contract owner to forcefully remove Regulators
    function removeRegulator(address toRemove) public ownerOnly {
        dataStorage.removeRegulator(toRemove);
    }

    // getter functions

    // check if an address is an authorised regulator
    function isAuthorised(address _address) public view returns(bool) {
        return dataStorage.isAuthorisedRegulator(_address);
    }

}