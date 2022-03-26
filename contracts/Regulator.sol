pragma solidity ^0.5.0;

import "./UserDataStorage.sol";

contract Regulator {
    address owner;

    struct RegulatorInformation {
        string name;
        bool authorised;
    }

    //mapping(address => RegulatorInformation) approved;
    mapping(address => uint256) queueNumber;
    mapping(uint256 => uint256) freeQueueNumbers;
    UserDataStorage u;
    uint256 nextQueueNumber;
    address[] approvalQueue;

    constructor() public {
        owner = msg.sender;
        }

    // testing functions just ignore


    //

    event approvalRequested(string companyName, address companyAddress);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed to do this.");
        _;
    }

    function setUserDataStorageAddress(address _address) public {
        u = UserDataStorage(_address);
    }

    function requestApproval(string memory name) public {
        require(queueNumber[msg.sender] == 0, 'Already in queue for Approval!');
    
        u.addRegulator(name, msg.sender, false);

        if (nextQueueNumber == 0) {
            approvalQueue.push(msg.sender);
            queueNumber[msg.sender] = approvalQueue.length;
        } else {
            approvalQueue[nextQueueNumber - 1] = msg.sender;
            queueNumber[msg.sender] = nextQueueNumber;
            uint256 next = freeQueueNumbers[nextQueueNumber];
            delete freeQueueNumbers[nextQueueNumber];
            nextQueueNumber = next;
        }
        emit approvalRequested(name, msg.sender);
    }

    function approveRegulator(address toApprove) public onlyOwner {
        u.updateRegulatorAuthorisation(toApprove, true);

        uint256 currentQueueNumber = queueNumber[toApprove];
        delete approvalQueue[currentQueueNumber - 1];
        freeQueueNumbers[currentQueueNumber] = nextQueueNumber;
        nextQueueNumber = currentQueueNumber;
        delete queueNumber[toApprove];

    }

    function rejectRegulator(address toReject) public onlyOwner {
        //delete approved[toReject];
        u.removeRegulator(toReject);
        
        uint256 openedSlot = queueNumber[toReject];
        freeQueueNumbers[openedSlot] = nextQueueNumber;
        nextQueueNumber = openedSlot;
        delete queueNumber[toReject];
    }

    function removeRegulator(address toRemove) public onlyOwner {
        //delete approved[toRemove];
        u.removeRegulator(toRemove);
    }

    function getApprovalQueue() public view returns(address[] memory) {
        return approvalQueue;
    }
    // getter functions
    function isAuthorised(address regulator) public view returns(bool) {
        bool authorised = u.getRegulatorAuthorisation(regulator);
        return authorised;
    }

}