pragma solidity ^0.5.0;

import './CarbonExchange.sol';

contract Wallet {
    address owner;
    address carbonExchange;

    mapping(address => uint256) eth_accounts;
    mapping(address => uint256) eth_locked;

    mapping(address => uint256) token_accounts;
    mapping(address => uint256) token_locked;

    modifier ownerOnly() {
        require(msg.sender == owner, 'Not owner of contract!');
        _;
    }

    modifier carbonExchangeContractOnly() {
        require(msg.sender == carbonExchange, 'Not authorised address!');
        _;
    }

    function setCarbonExchange(address _address) public ownerOnly {
        carbonExchange = _address;
    }

    // eth accounts

    function depositEth(address _address, uint256 amount) public carbonExchangeContractOnly {
        eth_accounts[_address] = eth_accounts[_address] + amount;
    }

    function withdrawETh(address _address) public carbonExchangeContractOnly {
        uint256 available_funds = eth_accounts[_address] - eth_locked[_address];
        require(available_funds > 0, 'Insufficient funds or funds are locked!');

        eth_accounts[_address] = eth_accounts[_address] - available_funds;
    }

    function addLockedEth(address _address, uint256 amount)  public carbonExchangeContractOnly {
        eth_locked[_address] = eth_locked[_address] + amount;
    }

    function reduceLockedEth(address _address, uint256 amount) public carbonExchangeContractOnly {
        uint256 locked_funds = eth_locked[_address] - amount;
        eth_locked[_address] = locked_funds >= 0 ? locked_funds : 0;
    }
    

    // getters
    function getWithdrawableEth(address _address) public view returns (uint256) {
        uint256 available_funds = eth_accounts[_address] - eth_locked[_address];
        return available_funds;
    }

    function getEthBalance(address _address) public view returns(uint256) {
        return eth_accounts[_address];
    }

}