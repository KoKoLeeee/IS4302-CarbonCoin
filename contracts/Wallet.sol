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

    function withdrawEth(address _address) public carbonExchangeContractOnly {
        require(getWithdrawableEth(_address) > 0, 'Insufficient funds or funds are locked!');

        eth_accounts[_address] -= getWithdrawableEth(_address);
    }

    function transferEth(address _from, address _to, uint256 amount) public carbonExchangeContractOnly {
        require(getEthBalance(_from) >= amount, 'Insufficient funds to transfer!');
        reduceLockedEth(_from, amount);
        eth_accounts[_from] -= amount;
        eth_accounts[_to] += amount;
    }

    function addLockedEth(address _address, uint256 amount)  public carbonExchangeContractOnly {
        eth_locked[_address] = eth_locked[_address] + amount;
    }

    function reduceLockedEth(address _address, uint256 amount) public carbonExchangeContractOnly {
        uint256 locked_funds = eth_locked[_address] - amount;
        eth_locked[_address] = locked_funds >= 0 ? locked_funds : 0;
    }

    // token accounts

    function depositTokens(address _address, uint256 amount) public carbonExchangeContractOnly {
        token_accounts[_address] += amount;
    }

    function withdrawTokens(address _address) public carbonExchangeContractOnly {
        require(getWithdrawableToken(_address) > 0, 'Insufficient tokens or tokens are locked!');
        token_accounts[_address] -= getWithdrawableToken(_address);
    }

    function transferToken(address _from, address _to, uint256 amount) public carbonExchangeContractOnly {
        require(getTokenBalance(_from) >= amount, 'Insufficient tokens to transfer!');
        reduceLockedToken(_from, amount);
        token_accounts[_from] -= amount;
        token_accounts[_to] += amount;
    }

    function addLockedToken(address _address, uint256 amount) public carbonExchangeContractOnly {
        token_locked[_address] = token_locked[_address] + amount;
    }

    function reduceLockedToken(address _address, uint256 amount) public carbonExchangeContractOnly {
        uint256 locked_token = token_locked[_address] - amount;
        token_locked[_address] = locked_token >= 0 ? locked_token : 0;
    }


    // getters
    function getWithdrawableEth(address _address) public view returns (uint256) {
        uint256 available_funds = eth_accounts[_address] - eth_locked[_address];
        return available_funds;
    }

    function getEthBalance(address _address) public view returns(uint256) {
        return eth_accounts[_address];
    }

    function getWithdrawableToken(address _address) public view returns (uint256) {
        uint256 available_tokens = token_accounts[_address] - token_locked[_address];
        return available_tokens;
    }

    function getTokenBalance(address _address) public view returns (uint256) {
        return token_accounts[_address];
    }

}