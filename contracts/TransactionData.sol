pragma solidity ^0.5.0;

import './Company.sol';

contract TransactionData {
    
    address owner;

    struct Transaction {
        address account;
        int256 amount;
        uint256 price;
    }

    address carbonExchange;

    Transaction[] data;

    modifier ownerOnly() {
        require(msg.sender == owner, 'Not owner of contract!');
        _;
    }

    modifier carbonExchangeContractOnly() {
        require(msg.sender == carbonExchange, 'Not authorised address!');
        _;
    }

    function setCarbonExchangeAddress(address _address) public ownerOnly {
        carbonExchange = _address;
    }

    function addTransaction(address account, int256 amount, uint256 price) public carbonExchangeContractOnly {
        data.push(Transaction({ account: account, amount: amount, price: price}));
    }
    
}