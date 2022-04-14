pragma solidity ^0.5.0;

import './CarbonExchange.sol';

contract Wallet {
    // owner of contract (governing body)
    address owner;

    // address of carbon exchange
    // allows only this address to make changes within this wallet.
    address carbonExchange;

    // mappings of address to their wallets and locked wallets as well.
    mapping(address => uint256) eth_accounts;
    mapping(address => uint256) eth_locked;

    mapping(address => uint256) token_accounts;
    mapping(address => uint256) token_locked;

    // events
    event CarbonExchangeAddressSet(address);

    constructor() public {
        owner = msg.sender;
    }

    // ----- modifiers ------

    // restricts access to owner of contract only
    modifier ownerOnly() {
        require(msg.sender == owner, 'Not owner of contract!');
        _;
    }

    // restricts access to address of carbone exchange set by owner
    modifier carbonExchangeContractOnly() {
        require(msg.sender == carbonExchange, 'Not authorised address!');
        _;
    }

    // ----- setters -----

    // sets the address of the carbon exchange
    function setCarbonExchangeAddress(address _address) public ownerOnly {
        carbonExchange = _address;
        emit CarbonExchangeAddressSet(_address);
    }

    // ----- Eth Wallet Functions -----

    // desposits ether into address account
    function depositEth(address _address, uint256 amount) public carbonExchangeContractOnly {
        eth_accounts[_address] = eth_accounts[_address] + amount;
    }

    // withdraws ether from address account
    function withdrawEth(address _address) public carbonExchangeContractOnly {
        require(getWithdrawableEth(_address) > 0, 'Insufficient funds or funds are locked!');
        eth_accounts[_address] -= getWithdrawableEth(_address);
    }

    // transfer ether from "_from" address to "_to" address
    function transferEth(address _from, address _to, uint256 amount) public carbonExchangeContractOnly {
        require(getEthBalance(_from) >= amount, 'Insufficient funds to transfer!');
        // reduceLockedEth(_from, amount);
        eth_accounts[_from] -= amount;
        eth_accounts[_to] += amount;
    }

    // locks ether in wallet, due to orders placed in the market
    function addLockedEth(address _address, uint256 amount)  public carbonExchangeContractOnly {
        eth_locked[_address] = eth_locked[_address] + amount;
    }

    // unlocks ether in wallet
    function reduceLockedEth(address _address, uint256 amount) public carbonExchangeContractOnly {
        uint256 locked_funds = eth_locked[_address] - amount;
        eth_locked[_address] = locked_funds >= 0 ? locked_funds : 0;
    }

    // ----- Token Wallet Functions -----

    // deposits tokens into address account
    function depositTokens(address _address, uint256 amount) public carbonExchangeContractOnly {
        token_accounts[_address] += amount;
    }

    // withdraws tokens from address account
    function withdrawTokens(address _address) public carbonExchangeContractOnly {
        require(getWithdrawableToken(_address) > 0, 'Insufficient tokens or tokens are locked!');
        token_accounts[_address] -= getWithdrawableToken(_address);
    }

    // transfer tokens from "_from" address to "_to" address
    function transferToken(address _from, address _to, uint256 amount) public carbonExchangeContractOnly {
        require(getTokenBalance(_from) >= amount, 'Insufficient tokens to transfer!');
        // reduceLockedToken(_from, amount);
        token_accounts[_from] -= amount;
        token_accounts[_to] += amount;
    }

    // locks tokens in wallet, due to orders placed in the market
    function addLockedToken(address _address, uint256 amount) public carbonExchangeContractOnly {
        token_locked[_address] = token_locked[_address] + amount;
    }
    
    // unlocks tokens in wallet
    function reduceLockedToken(address _address, uint256 amount) public carbonExchangeContractOnly {
        uint256 locked_token = token_locked[_address] - amount;
        token_locked[_address] = locked_token >= 0 ? locked_token : 0;
    }


    // ----- Getters -----

    // returns amount of (unlocked) Ether that can be withdrawn
    function getWithdrawableEth(address _address) public view returns (uint256) {
        uint256 available_funds = eth_accounts[_address] - eth_locked[_address];
        return available_funds;
    }

    // returns total amount of ether in wallet (locked + unlocked)
    function getEthBalance(address _address) public view returns(uint256) {
        return eth_accounts[_address];
    }

    // returns amount of (unlocked) tokens that can be withdrawn
    function getWithdrawableToken(address _address) public view returns (uint256) {
        uint256 available_tokens = token_accounts[_address] - token_locked[_address];
        return available_tokens;
    }

    // returns total amount of tokens in the wallet.
    function getTokenBalance(address _address) public view returns (uint256) {
        return token_accounts[_address];
    }

}