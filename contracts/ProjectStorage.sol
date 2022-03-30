pragma solidity ^0.5.0;

contract ProjectStorage {

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

    // access restrictions
    modifier approvedProjectContract() {
        require(msg.sender == projectAddress, 'Unauthorised address!');
        _;
    }

    function addProject(string memory projectName) public approvedProjectContract {
        projectInfo[numProjects] = ProjectInfo({ name: projectName, by: tx.origin, status: ProjectStatus.Requested, tokensAwarded: 0 });

        numProjects += 1;
    }

    function updateProject(uint256 projectId, ProjectStatus _status, uint256 awardedTokens) public approvedProjectContract {
        require(projectId < numProjects, "Invalid Project ID!");
        projectInfo[projectId].status = _status;
        projectInfo[projectId].tokensAwarded = awardedTokens;
    }

    // getters
    function getCompany(uint256 projectId) public view returns(address) {
        return projectInfo[projectId].by;
    }
}