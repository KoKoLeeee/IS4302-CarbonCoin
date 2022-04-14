pragma solidity ^0.5.0;

contract ProjectStorage {

    // owner of the contract (governing body)
    address owner;

    enum ProjectStatus {
        Requested,
        Approved,
        Rejected
    }

    struct ProjectInfo {
        uint256 projId;
        string name;
        address by;
        ProjectStatus status;
        uint256 tokensAwarded;
    }

    // address of Project
    // ensures that only this contract specified, is able to make changes to the data storage
    address projectAddress;

    // mapping projectID to project information
    mapping(uint256 => ProjectInfo) projectInfo;
    uint256 numProjects = 0;

    // events
    event ProjectAddressSet(address);

    constructor() public {
        owner = msg.sender;
    }

    // ----- modifiers -----

    // restricts access to owner of contract only
    modifier ownerOnly() {
        require(msg.sender == owner, 'Not owner of contract!');
        _; 
    }

    // restricts access to address of Project contract specified by owner
    modifier approvedProjectContract() {
        require(msg.sender == projectAddress, 'Unauthorised address!');
        _;
    }

    // ----- Setters -----
    function setProjectAddress(address _address) public ownerOnly() {
        projectAddress = _address;
        emit ProjectAddressSet(_address);
    }

    // ----- Class Functions -----

    // adds REQUESTED projects into storage
    function addProject(string memory projectName) public approvedProjectContract returns (uint256) {
        projectInfo[numProjects] = ProjectInfo({projId: numProjects, name: projectName, by: tx.origin, status: ProjectStatus.Requested, tokensAwarded: 0 });
        numProjects += 1;
        return numProjects - 1;
    }

    // update project details, for regulators to update status of project and how many tokens are awarded for this project
    function updateProject(uint256 projectId, ProjectStatus _status, uint256 awardedTokens) public approvedProjectContract {
        require(projectId < numProjects, "Invalid Project ID!");
        projectInfo[projectId].status = _status;
        projectInfo[projectId].tokensAwarded = awardedTokens;
    }

    // ----- Getters -----

    // returns company that proposed the project
    function getCompany(uint256 projectId) public view returns(address) {
        return projectInfo[projectId].by;
    }

    // returns amount of tokens awarded for project
    function getProjectRewards(uint256 projectId) public view returns (uint256) {
        return projectInfo[projectId].tokensAwarded;
    }

    // returns status of project
    function getProjectStatus(uint256 projectId) public view returns (ProjectStatus) {
        return projectInfo[projectId].status;
    }
}