pragma solidity ^0.5.0;

import './ERC20.sol';
import './Regulator.sol';
import './Company.sol';

contract CarbonToken {
    address _owner;
    ERC20 erc20;
    Regulator regulatorContract;
    Company companyContract;

    constructor(Regulator regulatorContractAddress, Company companyContractAddress) public {
        _owner = msg.sender;
        erc20 = new ERC20();
        regulatorContract = regulatorContractAddress;
        companyContract = companyContractAddress;
    }

    modifier companyOnly() {
        require(companyContract.isAuthorised(msg.sender), 'Not authorised as a Company!');
        _;
    }

    modifier regulatorOnly() {
        require(regulatorContract.isAuthorised(msg.sender), 'Not authorised as a Regulator!');
        _;
    }

    function mintFor(address _to, uint256 amount) public regulatorOnly {
        erc20.mint(_to, amount);
    }

    function destroyTokens(address _from, uint256 amount) public regulatorOnly {
        erc20.transferFrom(_from, address(0), amount);
    }


}