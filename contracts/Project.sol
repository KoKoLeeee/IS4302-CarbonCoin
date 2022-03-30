pragma solidity ^0.5.0;

import './Regulator.sol';
import './Company.sol';
import './ProjectStorage.sol';
import './CarbonToken.sol';

contract Project {
    Regulator regulatorContract;
    Company companyContract;

    ProjectStorage projectStorage;
    CarbonToken carbonContract;

    constructor(Regulator regulatorContractAddress, Company companyContractAddress, ProjectStorage projectStorageAddress) public {
        regulatorContract = regulatorContractAddress;
        companyContract = companyContractAddress;
        projectStorage = projectStorageAddress;
    }

    modifier companyOnly() {
        require(companyContract.isAuthorised(msg.sender), 'Not authorised Company!');
        _;
    }

    modifier regulatorOnly() {
        require(regulatorContract.isAuthorised(msg.sender), 'Not authorised Regulator!');
        _;
    }

    function requestProject(string memory projectName) public companyOnly {
        projectStorage.addProject(projectName);
    }

    function approveProject(uint256 projectId, uint256 awardedTokens) public regulatorOnly {
        projectStorage.updateProject(projectId, ProjectStorage.ProjectStatus.Approved, awardedTokens);
        carbonContract.mintFor(projectStorage.getCompany(projectId), awardedTokens);
    }

    function rejectProject(uint256 projectId) public regulatorOnly() {
        projectStorage.updateProject(projectId, ProjectStorage.ProjectStatus.Rejected, 0);
    }
    
}