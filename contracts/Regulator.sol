pragma solidity ^0.5.0;

contract Regulator {
    address owner;
    struct RegulatorInformation {
        string name;
        bool authorised;
    }

    mapping(address => RegulatorInformation) approved;
    mapping(address => uint256) queueNumber;
    mapping(uint256 => uint256) freeQueueNumbers;
    uint256 nextQueueNumber;
    address[] approvalQueue;

    constructor(string memory name) public {
        owner = msg.sender;
        approved[msg.sender] = RegulatorInformation({ name: name, authorised: true });
    }

    // testing functions just ignore


    //

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed to approve this.");
        _;
    }

    function requestApproval(string memory name) public {
        require(queueNumber[msg.sender] == 0, 'Already in queue for Approval!');
        
        approved[msg.sender] = RegulatorInformation({ name: name, authorised: false });

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
    }

    function approveRegulator(address toApprove) public onlyOwner {
        approved[toApprove].authorised = true;

        uint256 currentQueueNumber = queueNumber[toApprove];
        delete approvalQueue[currentQueueNumber - 1];
        freeQueueNumbers[currentQueueNumber] = nextQueueNumber;
        nextQueueNumber = currentQueueNumber;
    }

    function rejectRegulator(address toReject) public onlyOwner {
        delete approved[toReject];

        uint256 openedSlot = queueNumber[toReject];
        freeQueueNumbers[openedSlot] = nextQueueNumber;
        nextQueueNumber = openedSlot;
    }

    function removeRegulator(address toRemove) public onlyOwner {
        delete approved[toRemove];
    }

    function getApprovalQueue() public view returns(address[] memory) {
        return approvalQueue;
    }
    // getter functions
    function isAuthorised(address regulator) public view returns(bool) {
        return approved[regulator].authorised;
    }

}