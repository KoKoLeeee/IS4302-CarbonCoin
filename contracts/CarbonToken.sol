pragma solidity ^0.5.0;

import './ERC20.sol';
import './Regulator.sol';
import './Company.sol';
import './Project.sol';
import './CarbonExchange.sol';

contract CarbonToken {
    address _owner;
    ERC20 erc20;
    Regulator regulatorContract;
    Company companyContract;
    Project projectContract;
    address exchangeAddress;

    // events
    event CarbonExchangeAddressSet(address);
    event OwnerMint(address _to, uint256 amount);

    constructor(Regulator regulatorContractAddress, Company companyContractAddress, Project projectContractAddress) public {
        _owner = msg.sender;
        erc20 = new ERC20();
        regulatorContract = regulatorContractAddress;
        companyContract = companyContractAddress;
        projectContract = projectContractAddress;
    }

    modifier ownerOnly() {
        require(msg.sender == _owner, 'Not owner of contract!');
        _;
    }

    modifier companyOnly() {
        require(companyContract.isApproved(msg.sender), 'Not authorised as a Company!');
        _;
    }

    modifier regulatorOnly() {
        require(regulatorContract.isApproved(msg.sender), 'Not authorised as a Regulator!');
        _;
    }

    modifier exchangeAddressOnly() {
        require(msg.sender == exchangeAddress, 'Not authorised Exchange!');
        _;
    }

    function setCarbonExchangeAddress(address _address) public ownerOnly {
        exchangeAddress = _address;
        emit CarbonExchangeAddressSet(_address);
    }

    function mint(address _address, uint256 amount) public ownerOnly {
        erc20.mint(_address, amount);
        emit OwnerMint(_address, amount);
    }
    
    // MIGHT WANNA ADD AUTO + ONLY CAN CALL ONCE A YEAR.
    function mintForYear(address _address, uint256 year) public regulatorOnly {
        uint256 amount = companyContract.getYearLimit(_address, year);
        erc20.mint(_address, amount);
    }

    function mintForProject(uint256 projectId) public regulatorOnly {
        address awardee = projectContract.getCompany(projectId);
        uint256 amount = projectContract.getProjectRewards(projectId);
        erc20.mint(awardee, amount);
    }

    function destroyTokens(address _from, uint256 amount) public regulatorOnly {
        erc20.transferFrom(_from, address(0), amount);
    }

    function transfer(address _from, address _to, uint256 amount) public exchangeAddressOnly {
        erc20.transferFrom(_from, _to, amount);
    }

}