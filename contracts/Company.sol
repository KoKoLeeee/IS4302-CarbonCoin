pragma solidity ^0.5.0;

import "./UserDataStorage.sol";

contract Company {
    address owner;

    UserDataStorage dataStorage;
    mapping(address => uint256) queueNumber;
    mapping(uint256 => uint256) freeQueueNumbers;
    uint256 nextQueueNumber;
    address[] approvalQueue;

    event approvalRequested(string companyName, address companyAddress);

    constructor() public {
        owner = msg.sender;
    }

    // Access Restriction to only allow approved regulators to call methods
    modifier onlyAuthorisedRegulator() {
        // (string memory name, bool authorised) = u.regulators(msg.sender);
        require(dataStorage.getRegulatorStatus(msg.sender) == UserDataStorage.Status.Approved, "Only approved regulators are allowed to do this.");
        _;
    }

    // setter for UserDataStorage
    function setUserDataStorageAddress(address _address) public {
        dataStorage = UserDataStorage(_address);
    }

    // For companies to request to become an authorised company.
    function requestApproval(string memory name) public {
        // Checks if they are already in the queue
        require(queueNumber[msg.sender] == 0, 'Already in queue for Approval!');
        
        // Adds CompanyInformation to datastorage. Not yet approved.
        dataStorage.addCompany(name, msg.sender, UserDataStorage.Status.Requested);

        // Checks the next available queue number in approvalQueue
        if (nextQueueNumber == 0) {
            // if no available queue number, push to back of the list
            approvalQueue.push(msg.sender);
            queueNumber[msg.sender] = approvalQueue.length;
        } else {
            // if queue number available, insert into index coresspeonding to queue number in the list
            approvalQueue[nextQueueNumber - 1] = msg.sender;
            queueNumber[msg.sender] = nextQueueNumber;

            // update next available queue number
            uint256 next = freeQueueNumbers[nextQueueNumber];
            delete freeQueueNumbers[nextQueueNumber];
            nextQueueNumber = next;
        }
        emit approvalRequested(name, msg.sender);
    }

    // For Regulators to authorised companies
    function approveCompany(address toApprove) public onlyAuthorisedRegulator {
        // Ensures that address must be in the queue
        require(queueNumber[toApprove] != 0, 'Address not in queue yet!');

        // Update UserDataStorage
        dataStorage.updateCompanyAuthorisation(toApprove, UserDataStorage.Status.Approved);

        // update queue status and queue numbers
        uint256 currentQueueNumber = queueNumber[toApprove];
        delete approvalQueue[currentQueueNumber - 1];
        freeQueueNumbers[currentQueueNumber] = nextQueueNumber;
        nextQueueNumber = currentQueueNumber;
        delete queueNumber[toApprove];
    }

    // For Regulators to reject companies
    function rejectCompany(address toReject) public onlyAuthorisedRegulator {
        // Ensures that address must be in the queue
        require(queueNumber[toReject] != 0, 'Address not in queue yet!');

        // Update UserDataStorage
        dataStorage.removeCompany(toReject);

        // Update queue status and queue numbers
        uint256 openedSlot = queueNumber[toReject];
        freeQueueNumbers[openedSlot] = nextQueueNumber;
        nextQueueNumber = openedSlot;
        delete queueNumber[toReject];
    }

    // For regulators to forcefully remove companies
    function removeCompany(address toRemove) public onlyAuthorisedRegulator {
        dataStorage.removeCompany(toRemove);
    }

    function reportEmissions(address company, uint256 year, uint256 emissions) public onlyAuthorisedRegulator {
        dataStorage.updateCompanyEmissions(company, year, emissions);
    }

    function getApprovalQueue() public view returns(address[] memory) {
        return approvalQueue;
    }
    // getter functions
    function isAuthorised(address _address) public view returns(bool) {
        return dataStorage.getCompanyStatus(_address) == UserDataStorage.Status.Approved;
    }

}