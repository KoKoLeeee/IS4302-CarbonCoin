pragma solidity ^0.5.0;

import './ERC20.sol';
import './Regulator.sol';
import './Company.sol';
import './Project.sol';
import './CarbonExchange.sol';

contract CarbonToken {
    // owner of the contract (governing body)
    address owner;
    ERC20 erc20;
    Regulator regulatorContract;
    Company companyContract;
    Project projectContract;
    address exchangeAddress;

    // events
    event CarbonExchangeAddressSet(address);
    event OwnerMint(address _to, uint256 amount);
    event mintedForProject(address, uint256, uint256);
    event mintedForYear(address, uint256);
    event TokensDestroyed(address, uint256);

    constructor(Regulator regulatorContractAddress, Company companyContractAddress, Project projectContractAddress) public {
        owner = msg.sender;
        erc20 = new ERC20();
        regulatorContract = regulatorContractAddress;
        companyContract = companyContractAddress;
        projectContract = projectContractAddress;
    }

    // ----- modifiers -----    

    // Restict access to owner of contract only
    modifier ownerOnly() {
        require(msg.sender == owner, 'Not owner of contract!');
        _;
    }

    // Restrict access to approved companies only
    modifier companyOnly() {
        require(companyContract.isApproved(msg.sender), 'Not authorised as a Company!');
        _;
    }

    // Restrict access to approved regulators only
    modifier regulatorOnly() {
        require(regulatorContract.isApproved(msg.sender), 'Not authorised as a Regulator!');
        _;
    }

    // Restrict access to address of carbon exchange set by owner only
    modifier exchangeAddressOnly() {
        require(msg.sender == exchangeAddress, 'Not authorised Exchange!');
        _;
    }

    // ------ setters -----

    // setter for carbon exchange address
    function setCarbonExchangeAddress(address _address) public ownerOnly {
        exchangeAddress = _address;
        emit CarbonExchangeAddressSet(_address);
    }

    // ----- Class Functions -----

    // Adminstrative Minting for Testing purposes. Only available to owner
    function mint(address _address, uint256 amount) public ownerOnly {
        erc20.mint(_address, amount);
        emit OwnerMint(_address, amount);
    }
    
    // allows regulators to mint tokens based on companies yearly emission limit 
    function mintForYear(address _address, uint256 year) public regulatorOnly {
        uint256 amount = companyContract.getYearLimit(_address, year);
        erc20.mint(_address, amount);
        emit mintedForYear(_address, year);
    }

    // allows regulators to mint tokens for approved projects
    function mintForProject(uint256 projectId) public regulatorOnly {
        address awardee = projectContract.getCompany(projectId);
        uint256 amount = projectContract.getProjectRewards(projectId);
        erc20.mint(awardee, amount);
        emit mintedForProject(awardee, amount, projectId);
    }

    // to destroy tokens that have been consumed / used by companies.
    function destroyTokens(address _from, uint256 amount) public regulatorOnly {
        erc20.transferFrom(_from, address(0), amount);
        emit TokensDestroyed(_from, amount);
    }

    // for transfer of tokens to be used by carbon exchange to aid in buy / sell of tokens
    function transfer(address _from, address _to, uint256 amount) public exchangeAddressOnly {
        erc20.transferFrom(_from, _to, amount);
    }

    // ----- getters -----

    // get token balance of specified address
    function getTokenBalance(address _address) public view returns (uint256) {
        return erc20.balanceOf(_address);
    }

}