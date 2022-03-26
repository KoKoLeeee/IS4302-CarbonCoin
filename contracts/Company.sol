pragma solidity ^0.5.0;

import "./UserDataStorage.sol";

contract Company {
    address owner;

    struct CompanyInformation {
        string name;
        bool authorised;
    }

    struct RegulatorInformation {
        string name;
        bool authorised;
    }    

    mapping(address => uint256) queueNumber;
    mapping(uint256 => uint256) freeQueueNumbers;
    UserDataStorage u;
    uint256 nextQueueNumber;
    address[] approvalQueue;

    constructor() public {
        owner = msg.sender;
        }

    event approvalRequested(string companyName, address companyAddress);

    modifier onlyAuthorisedRegulator() {
        (string memory name, bool authorised) = u.regulators(msg.sender);
        require(authorised == true, "Only approved regulators are allowed to do this.");
        _;
    }

    function setUserDataStorageAddress(address _address) public {
        u = UserDataStorage(_address);
    }

    function requestApproval(string memory name) public {
        require(queueNumber[msg.sender] == 0, 'Already in queue for Approval!');
        u.addCompany(name, msg.sender, false);

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

    function approveCompany(address toApprove) public onlyAuthorisedRegulator {
        u.updateCompanyAuthorisation(toApprove, true);
        uint256 currentQueueNumber = queueNumber[toApprove];
        delete approvalQueue[currentQueueNumber - 1];
        freeQueueNumbers[currentQueueNumber] = nextQueueNumber;
        nextQueueNumber = currentQueueNumber;
        delete queueNumber[toApprove];
    }

    function rejectCompany(address toReject) public onlyAuthorisedRegulator {
        u.removeCompany(toReject);
        uint256 openedSlot = queueNumber[toReject];
        freeQueueNumbers[openedSlot] = nextQueueNumber;
        nextQueueNumber = openedSlot;
        delete queueNumber[toReject];
    }

    function removeCompany(address toRemove) public onlyAuthorisedRegulator {
        u.removeCompany(toRemove);
    }

    function getApprovalQueue() public view returns(address[] memory) {
        return approvalQueue;
    }
    // getter functions
    function isAuthorised(address _address) public view returns(bool) {
        bool authorised = u.getCompanyAuthorisation(_address);
        return authorised;
    }

}