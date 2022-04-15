pragma solidity ^0.5.0;

import './Regulator.sol';
import './Company.sol';
import './ProjectStorage.sol';
import './CarbonToken.sol';

contract Project {
    address owner;
    Regulator regulatorContract;
    Company companyContract;

    // ProjectStorage instance to hold data on ProjectInformation
    ProjectStorage projectStorage;

    // events
    event projectRequested(address requester, string projectName, uint256 projId);
    event projectRejected(address rejector, uint256 projId);
    event projectApproved(address approver, uint256 projId, uint256 awardedTokens);

    constructor(Regulator regulatorContractAddress, Company companyContractAddress, ProjectStorage projectStorageAddress) public {
        owner = msg.sender;
        regulatorContract = regulatorContractAddress;
        companyContract = companyContractAddress;
        projectStorage = projectStorageAddress;
    }

    // ----- modifiers -----
    
    // restricts access to approved companies only
    modifier companyOnly() {
        require(companyContract.isApproved(msg.sender), 'Not authorised Company!');
        _;
    }

    // restricts access to approved regulators only
    modifier regulatorOnly() {
        require(regulatorContract.isApproved(msg.sender), 'Not authorised Regulator!');
        _;
    }

    // ----- Class Functions -----

    // to allows companies to request a project.
    function requestProject(string memory projectName) public companyOnly returns (uint256) {
        uint256 projId = projectStorage.addProject(projectName);
        emit projectRequested(msg.sender, projectName, projId);
        return projId;
    }

    // to allow regulators to approve a project, and award them tokens accordingly.
    function approveProject(uint256 projectId, uint256 awardedTokens) public regulatorOnly {
        projectStorage.updateProject(projectId, ProjectStorage.ProjectStatus.Approved, awardedTokens);
        emit projectApproved(msg.sender, projectId, awardedTokens);
    }

    // to allow regulators to reject a project
    function rejectProject(uint256 projectId) public regulatorOnly() {
        projectStorage.updateProject(projectId, ProjectStorage.ProjectStatus.Rejected, 0);
        emit projectRejected(msg.sender, projectId);
    }

    // ------- getters function ------
    
    // returns company behind the project
    function getCompany(uint256 projectId) public view returns (address) {
        return projectStorage.getCompany(projectId);
    }

    // returns tokens awarded for the project
    function getProjectRewards(uint256 projectId) public view returns (uint256) {
        return projectStorage.getProjectRewards(projectId);
    }

    // returns status of the project.
    function getProjectStatus(uint256 projectId) public view returns (ProjectStorage.ProjectStatus) {
        return projectStorage.getProjectStatus(projectId);
    }
    
}