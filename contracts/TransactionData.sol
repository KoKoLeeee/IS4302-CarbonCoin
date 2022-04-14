pragma solidity ^0.5.0;

import './Company.sol';

contract TransactionData {
    
    // owner of contract (governing body)
    address owner;
    // address of carbon exchange that can update data storage
    address carbonExchange;

    // structure for a Transaction
    // account is the address of the user that made the transaction
    // amount is the amount of tokens transacted (negative value means tokens was sold, positive value means tokens was bought)
    // price is the price at which tokens were transacted at.
    struct Transaction {
        address account;
        int256 amount;
        uint256 price;
    }
    
    // list of transaction data
    Transaction[] data;

    // events
    event CarbonExchangeAddressSet(address);

    constructor() public {
        owner = msg.sender;
    }

    // ----- modifiers -----

    // restricts access to owner of contract only
    modifier ownerOnly() {
        require(msg.sender == owner, 'Not owner of contract!');
        _;
    }

    // restricts access to carbon exchange whose address was set by owner
    modifier carbonExchangeContractOnly() {
        require(msg.sender == carbonExchange, 'Not authorised address!');
        _;
    }

    // ----- Setters -----

    // sets address of carbon exchange contract
    function setCarbonExchangeAddress(address _address) public ownerOnly {
        carbonExchange = _address;
        emit CarbonExchangeAddressSet(_address);
    }

    // ----- Class Functions -----

    // adds transactions into the logs
    function addTransaction(address account, int256 amount, uint256 price) public carbonExchangeContractOnly {
        data.push(Transaction({ account: account, amount: amount, price: price}));
    }
    
}