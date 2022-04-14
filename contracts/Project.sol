pragma solidity ^0.5.0;

import './Regulator.sol';
import './Company.sol';
import './ProjectStorage.sol';
import './CarbonToken.sol';

contract Project {
    Regulator regulatorContract;
    Company companyContract;

    ProjectStorage projectStorage;
    // CarbonToken carbonContract;

    enum ProjectStatus {
        Requested,
        Approved,
        Rejected
    }


    event projectRequested(address requester, string projectName, uint256 projId);
    event projectRejected(address rejector, uint256 projId);
    event projectApproved(address approver, uint256 projId, uint256 awardedTokens);

    constructor(Regulator regulatorContractAddress, Company companyContractAddress, ProjectStorage projectStorageAddress) public {
        regulatorContract = regulatorContractAddress;
        companyContract = companyContractAddress;
        projectStorage = projectStorageAddress;
    }

    modifier companyOnly() {
        require(companyContract.isApproved(msg.sender), 'Not authorised Company!');
        _;
    }

    modifier regulatorOnly() {
        require(regulatorContract.isApproved(msg.sender), 'Not authorised Regulator!');
        _;
    }

    function requestProject(string memory projectName) public companyOnly returns (uint256) {
        uint256 projId = projectStorage.addProject(projectName);
        emit projectRequested(msg.sender, projectName, projId);
        return projId;
    }

    function approveProject(uint256 projectId, uint256 awardedTokens) public regulatorOnly {
        projectStorage.updateProject(projectId, ProjectStorage.ProjectStatus.Approved, awardedTokens);
        // carbonContract.mintFor(projectStorage.getCompany(projectId), awardedTokens);
        emit projectApproved(msg.sender, projectId, awardedTokens);
    }

    function rejectProject(uint256 projectId) public regulatorOnly() {
        projectStorage.updateProject(projectId, ProjectStorage.ProjectStatus.Rejected, 0);
        emit projectRejected(msg.sender, projectId);
    }

    // ------- getters function ------
    function getCompany(uint256 projectId) public view returns (address) {
        return projectStorage.getCompany(projectId);
    }

    function getProjectRewards(uint256 projectId) public view returns (uint256) {
        return projectStorage.getProjectRewards(projectId);
    }

    function getProjectStatus(uint256 projectId) public view returns (ProjectStorage.ProjectStatus) {
        return projectStorage.getProjectStatus(projectId);
    }
    
}