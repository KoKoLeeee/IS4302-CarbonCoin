pragma solidity ^0.5.0;

import './Company.sol';
import './CarbonToken.sol';
import './TransactionData.sol';
import './Wallet.sol';

contract CarbonExchange {
    address owner = msg.sender;
    Wallet wallet;

    struct OrderInfo {
        address seller;
        uint256 amount;
    }

    struct OrderList {
        OrderInfo[] orders;
        uint256 front;
        uint256 end;
    }

    struct Spread {
        mapping(uint256 => OrderList) bid;
        mapping(uint256 => uint256) nextClosest;
        uint256 closest;
    }

    Spread bid;
    Spread ask;
    
    // map from address to price to amount
    mapping(address => mapping(uint256 => int256)) addressOrders;

    Company companyContract;
    address exchangeContract;
    TransactionData transactions;

    // access restriction
    modifier companyOnly() {
        require(companyContract.isAuthorised(msg.sender), 'Not authorised company!');
        _;
    }

    modifier ownerOnly() {
        require(msg.sender == owner, 'Not owner of contract!');
        _;
    }

    function setWallet(Wallet walletAddress) public ownerOnly {
        wallet = walletAddress;
    }
    
    // storing transaction data
    function logTransaction(address _address, int256 amount, uint256 price) public {
        transactions.addTransaction(_address, amount, price);
    }

    function placeBidOrder(uint256 amount, uint256 price) public payable {
        // if bid order is higher than lowest ask price, immediately fill order
        wallet.depositEth(msg.sender, msg.value);
        uint256 availableEth = wallet.getWithdrawableEth(msg.sender);
        require(availableEth >= amount * price, 'Insufficient funds! Please top up!');
        wallet.addLockedEth(msg.sender, amount*price);



    }

    function removeBidOrder(uint256 amount, uint256 price) public {

    }

    function placeAskOrder(uint256 amount, uint256 price) public {

    }

    function removeAskOrder(uint256 amount, uint256 price) public {

    }



    
}