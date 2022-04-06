pragma solidity ^0.5.0;

contract ProjectStorage {

    address owner;

    enum ProjectStatus {
        Requested,
        Approved,
        Rejected
    }

    struct ProjectInfo {
        string name;
        address by;
        ProjectStatus status;
        uint256 tokensAwarded;
    }

    address projectAddress;
    mapping(uint256 => ProjectInfo) projectInfo;
    uint256 numProjects = 0;

    constructor() public {
        owner = msg.sender;
    }

    // ------ modifiers ------

    // access restrictions
    modifier ownerOnly() {
        require(msg.sender == owner, 'Not owner of contract!');
        _; 
    }

    modifier approvedProjectContract() {
        require(msg.sender == projectAddress, 'Unauthorised address!');
        _;
    }

    // ------ Class Functions ------
    function setProjectAddress(address _address) public ownerOnly() {
        owner = _address;
    }

    // adds project details into storage
    function addProject(string memory projectName) public approvedProjectContract {
        projectInfo[numProjects] = ProjectInfo({ name: projectName, by: tx.origin, status: ProjectStatus.Requested, tokensAwarded: 0 });
        numProjects += 1;
    }

    // update project details
    function updateProject(uint256 projectId, ProjectStatus _status, uint256 awardedTokens) public approvedProjectContract {
        require(projectId < numProjects, "Invalid Project ID!");
        projectInfo[projectId].status = _status;
        projectInfo[projectId].tokensAwarded = awardedTokens;
    }

    // ------- getter methods ------
    function getCompany(uint256 projectId) public view returns(address) {
        return projectInfo[projectId].by;
    }

    function getProjectRewards(uint256 projectId) public view returns (uint256) {
        return projectInfo[projectId].tokensAwarded;
    }
}