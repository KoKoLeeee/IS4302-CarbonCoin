pragma solidity ^0.5.0;

import "./UserDataStorage.sol";

contract Regulator {
    // owner of the contract (governing body)
    address owner;
    // UserDataStorage instance that is holding the data of Approved Regulators.
    UserDataStorage dataStorage;

    // events
    event ApprovedRegulator(address);
    event RemovedRegulator(address);

    constructor(UserDataStorage dataStorageAddress) public {
        owner = msg.sender;
        dataStorage = dataStorageAddress;
    }

    // ------ modifiers ------

    // Restrict access to owner of contract only
    modifier ownerOnly() {
        require(msg.sender == owner, "Only Governing Body (owner) is allowed to do this.");
        _;
    }

    // ----- Setters -----

    // setter for UserDataStorage.
    function setUserDataStorageAddress(address _address) public ownerOnly {
        dataStorage = UserDataStorage(_address);
    }
    
    // ----- Class Functions -----

    // For owner to approve Regulators
    function approveRegulator(string memory name, string memory country, address toApprove) public ownerOnly {
        dataStorage.addRegulator(name, country, toApprove);
        emit ApprovedRegulator(toApprove);
    }

    // For owner to forcefully remove Regulators
    function removeRegulator(address toRemove) public ownerOnly {
        dataStorage.removeRegulator(toRemove);
        emit RemovedRegulator(toRemove);
    }

    // ----- Getters -----

    // returns True if  address is an approved regulator
    function isApproved(address _address) public view returns(bool) {
        return dataStorage.isApprovedRegulator(_address);
    }

}