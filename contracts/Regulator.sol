pragma solidity ^0.5.0;

import "./UserDataStorage.sol";

contract Regulator {
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

    // Access Restriction to only allow owner of contract to call methods.
    modifier ownerOnly() {
        require(msg.sender == owner, "Only owner is allowed to do this.");
        _;
    }

    // setter for UserDataStorage.
    function setUserDataStorageAddress(address _address) public ownerOnly {
        dataStorage = UserDataStorage(_address);
    }
    
    // For users to request to become a Regulator.
    function requestApproval(string memory name) public {
        // Checks if they are already in the queue
        require(queueNumber[msg.sender] == 0, 'Already in queue for Approval!');
    
        // Adds RegulatorInformation to the datastorage. Not yet approved.
        dataStorage.addRegulator(name, msg.sender, UserDataStorage.Status.Requested);

        // Checks the next available queue number in approvalQueue
        if (nextQueueNumber == 0) {
            // if no available queue number, push to back of the list.
            approvalQueue.push(msg.sender);
            queueNumber[msg.sender] = approvalQueue.length;
        } else {
            // if queue number available, insert into index corresponding to queue number in the list.
            approvalQueue[nextQueueNumber - 1] = msg.sender;
            queueNumber[msg.sender] = nextQueueNumber;

            // update next available queue number
            uint256 next = freeQueueNumbers[nextQueueNumber];
            delete freeQueueNumbers[nextQueueNumber];
            nextQueueNumber = next;
        }

        emit approvalRequested(name, msg.sender);
    }

    // For contract owner to approve Regulators
    function approveRegulator(address toApprove) public ownerOnly {
        // Ensures that address must be in the queue.
        require(queueNumber[toApprove] != 0, 'Address not in queue yet!');

        // Update UserDataStorage.
        dataStorage.updateRegulatorAuthorisation(toApprove, UserDataStorage.Status.Approved);

        // update queue status and queue numbers.
        uint256 currentQueueNumber = queueNumber[toApprove];
        delete approvalQueue[currentQueueNumber - 1];
        freeQueueNumbers[currentQueueNumber] = nextQueueNumber;
        nextQueueNumber = currentQueueNumber;
        delete queueNumber[toApprove];

    }

    // For contract owner to reject Regulators
    function rejectRegulator(address toReject) public ownerOnly {
        // Ensures that address must be in the queue
        require(queueNumber[toReject] != 0, 'Address not in queue yet!');
        
        // Updata UserDataStorage
        dataStorage.updateRegulatorAuthorisation(toReject, UserDataStorage.Status.Rejected);
        
        // Update queue status and queue numbers
        uint256 openedSlot = queueNumber[toReject];
        freeQueueNumbers[openedSlot] = nextQueueNumber;
        nextQueueNumber = openedSlot;
        delete queueNumber[toReject];
    }

    // For contract owner to forcefully remove Regulators
    function removeRegulator(address toRemove) public ownerOnly {
        // Update UserDataStorage
        dataStorage.updateRegulatorAuthorisation(toRemove, UserDataStorage.Status.Rejected);
    }

    // getter functions

    // get Queue
    function getApprovalQueue() public view returns(address[] memory) {
        return approvalQueue;
    }

    // check if an address is an approve regulator
    function isAuthorised(address _address) public view returns(bool) {
        return dataStorage.getRegulatorStatus(_address) == UserDataStorage.Status.Approved;
    }

}