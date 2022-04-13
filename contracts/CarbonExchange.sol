pragma solidity ^0.5.0;

import './Company.sol';
import './CarbonToken.sol';
import './TransactionData.sol';
import './Wallet.sol';

contract CarbonExchange {
    address owner = msg.sender;
    Wallet wallet;

    struct OrderInfo {
        address account_address;
        int256 amount;
    }

    struct OrderList {
        OrderInfo[] orders;
        uint256 front;
        uint256 end;
    }

    struct Spread {
        mapping(uint256 => OrderList) prices;
        mapping(uint256 => uint256) nextClosest;
        uint256 closest;
    }

    Spread bid;
    Spread ask;
    
    // map from address to price to amount
    mapping(address => mapping(uint256 => int256)) addressOrders;

    CarbonToken tokenContract;
    Company companyContract;
    TransactionData transactions;

    // events
    event PlacedBidOrder(address _address, uint256 amount, uint256 price);
    event FilledBidOrder(address _address, uint256 amount, uint256 price);
    event RemovedBidOrder(address _address, uint256 amount, uint256 price);
    event PlacedAskOrder(address _address, uint256 amount, uint256 price);
    event FilledAskOrder(address _address, uint256 amount, uint256 price);
    event RemovedAskOrder(address _address, uint256 amount, uint256 price);

    event DepositEth(address _address, uint256 amount);
    event WithdrawEth(address _address, uint256 amount);
    event DepositToken(address _address, uint256 amount);
    event WithdrawToken(address _address, uint256 amount);

    event WalletLockEth(address _address, uint256 amount);
    event WalletUnlockEth(address _address, uint256 amount);
    event WalletTransferEth(address _from, address _to, uint256 amount);
    event WalletLockToken(address _address, uint256 amount);
    event WalletUnlockToken(address _address, uint256 amount);
    event WalletTransferToken(address _from, address _to, uint256 amount);
    
    constructor(Wallet walletAddress, TransactionData transactionsAddress, CarbonToken tokenAddress, Company companyAddress) public {
        wallet = walletAddress;
        transactions = transactionsAddress;
        tokenContract = tokenAddress;
        companyContract = companyAddress;
    }

    // ------ modifiers ------

    // access restriction
    modifier companyOnly() {
        require(companyContract.isApproved(msg.sender), 'Not authorised company!');
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
    function logTransaction(address _address, int256 amount, uint256 price) private {

        // amount > 0 implies its a buy transaction.
        // amount < 0 implies its a sell tranasction.
        transactions.addTransaction(_address, amount, price);
    }

    function depositToken(uint256 amount) public companyOnly {
        
        tokenContract.transfer(msg.sender, address(this), amount);
        wallet.depositTokens(msg.sender, amount);
        emit DepositToken(msg.sender, amount);
    }

    function placeBidOrder(uint256 amount, uint256 price) public payable {
        
        // update balance of eth in wallet
        if (msg.value > 0) {
            wallet.depositEth(msg.sender, msg.value);
            emit DepositEth(msg.sender, msg.value);
        }
        // ensure there is no other ask orders at this price
        require(addressOrders[msg.sender][price] >= 0, 'Currently have ask order at this price!');
        // ensure that there is sufficient funds in wallet to make the purchase
        uint256 availableEth = wallet.getWithdrawableEth(msg.sender);
        require(availableEth >= amount * price, 'Insufficient funds! Please top up!');
        // lock necessary eth in the wallet.
        wallet.addLockedEth(msg.sender, amount*price);
        emit WalletLockEth(msg.sender, amount*price);

        // if bid price is higher than the lowest ask price, can fill order.
        uint256 biddingPrice = price;
        uint256 lowestAskPrice = ask.closest;

        

        // if there is a asking price lower than the bidding price and order is not fully filled yet
        while (lowestAskPrice != 0 && biddingPrice >= lowestAskPrice && amount > 0) {
            // get lowest asker
            OrderList memory orderLst = ask.prices[lowestAskPrice];
            uint256 front = orderLst.front;
            uint256 end = orderLst.end;
            
            // while ask queue at "lowest" price is not empty
            while (front < end) {
                // iterating through the asking orders at "lowest" price.
                OrderInfo memory orderInfo = orderLst.orders[front];
                uint256 sellerAmount = orderInfo.amount >= 0 ? uint256(orderInfo.amount) : uint256(-orderInfo.amount);
                
                // skip if the seller has cancelled the ask order.
                if (addressOrders[orderInfo.account_address][lowestAskPrice] >= 0) {
                    front += 1;
                    continue;
                }

                if (sellerAmount >= amount) {
                    // if a ask order can cover the total bid order
                    
                    // transfer Eth in wallet
                    wallet.reduceLockedEth(msg.sender, amount * biddingPrice);
                    emit WalletUnlockEth(msg.sender, amount*biddingPrice);
                    wallet.transferEth(msg.sender, orderInfo.account_address, amount * lowestAskPrice);
                    emit WalletTransferEth(msg.sender, orderInfo.account_address, amount * lowestAskPrice);

                    // transfer tokens in wallet
                    wallet.reduceLockedToken(orderInfo.account_address, amount);
                    emit WalletUnlockToken(orderInfo.account_address, amount);
                    wallet.transferToken(orderInfo.account_address, msg.sender, amount);
                    emit WalletTransferToken(orderInfo.account_address, msg.sender, amount);
                    
                    // Log sell transaction for ask order fulfilled.
                    logTransaction(orderInfo.account_address, int256(-amount), lowestAskPrice);
                    emit FilledAskOrder(orderInfo.account_address, amount, lowestAskPrice);
                    // log buy transaction for bid order fulfilled.
                    logTransaction(msg.sender, int256(amount), lowestAskPrice);
                    emit FilledBidOrder(msg.sender, amount, lowestAskPrice);

                    sellerAmount -= amount;
                    amount = 0;

                    // update ask orders
                    ask.prices[lowestAskPrice].orders[front].amount = int256(-sellerAmount);
                    // update addressOrders
                    addressOrders[orderInfo.account_address][lowestAskPrice] = int256(-sellerAmount);

                    // order has been fulfilled break loop.
                    break;
                } else {
                    // if a ask order can only partially cover the total bid order

                    // transfer Eth in wallet
                    wallet.reduceLockedEth(msg.sender, sellerAmount * biddingPrice);
                    emit WalletUnlockEth(msg.sender, sellerAmount * biddingPrice);
                    wallet.transferEth(msg.sender, orderInfo.account_address, sellerAmount * lowestAskPrice);
                    emit WalletTransferEth(msg.sender, orderInfo.account_address, sellerAmount * lowestAskPrice);

                    // transfer tokens in wallet
                    wallet.reduceLockedToken(orderInfo.account_address, sellerAmount);
                    emit WalletUnlockToken(orderInfo.account_address, sellerAmount);
                    wallet.transferToken(orderInfo.account_address, msg.sender, sellerAmount);
                    emit WalletTransferToken(orderInfo.account_address, msg.sender, amount);
                    
                    // Log sell transaction for ask order fulfilled
                    logTransaction(orderInfo.account_address, int256(-sellerAmount), lowestAskPrice);
                    emit FilledAskOrder(orderInfo.account_address, sellerAmount, lowestAskPrice);
                    // log buy transaction for bid order fulfilled.
                    logTransaction(msg.sender, int256(sellerAmount), lowestAskPrice);
                    emit FilledBidOrder(msg.sender, sellerAmount, lowestAskPrice);

                    amount -= sellerAmount;
                    sellerAmount = 0;

                    // update ask orders
                    ask.prices[lowestAskPrice].orders[front].amount = 0;
                    // update addressOrders
                    addressOrders[orderInfo.account_address][lowestAskPrice] = 0;

                }
                front += 1;
            }

            if (front == end) {
                bid.prices[lowestAskPrice].front = 0;
                bid.prices[lowestAskPrice].end = 0;
                // get the next "lowest" asking price
                uint256 next = ask.nextClosest[lowestAskPrice];
                ask.closest = next;
                delete ask.nextClosest[lowestAskPrice];
                lowestAskPrice = ask.closest;
            } else {
                ask.prices[lowestAskPrice].front = front;
            }
        }

        // if order is not fully fulfilled yet, add to bid orders.
        if (amount > 0) {
            uint256 highest = bid.closest;

            if (price > highest) {
                // if bid price is higher than all the other bid orders.
                
                bid.nextClosest[price] = bid.closest;
                bid.closest = price;
            
            } else {
                // if bid price is NOT higher than all other bid orders

                uint256 current = highest;
                uint256 previous;
                // find mapping where by current > price
                while (current > price) {
                    previous = current;
                    current = bid.nextClosest[current];
                }
                bid.nextClosest[previous] = price;
                bid.nextClosest[price] = current;
            }

            // add OrderInfo to queue of bid orders with the same bid price.
            bid.prices[price].orders.push(OrderInfo({account_address: msg.sender, amount: int256(amount)}));
            bid.prices[price].end += 1;
            // update address's orders
            addressOrders[msg.sender][price] = int256(amount);
            emit PlacedBidOrder(msg.sender, amount, price);
        }
    }

    function removeBidOrder(uint256 price) public {
        require(addressOrders[msg.sender][price] > 0, 'No current Bid orders!');
        uint256 amount = uint256(addressOrders[msg.sender][price]);
        addressOrders[msg.sender][price] = 0;

        wallet.reduceLockedEth(msg.sender, amount*price);
        emit WalletUnlockEth(msg.sender, amount*price);

        emit RemovedBidOrder(msg.sender, amount, price);
    }

    function placeAskOrder(uint256 amount, uint256 price) public {
        // ensure there is no other bidOrders at this price for seller.
        require(addressOrders[msg.sender][price] <= 0, 'Currently have bid order at this price!');
        // ensure there is sufficient tokens in wallet to make the purchase
        require(wallet.getWithdrawableToken(msg.sender) >= amount, 'Insufficient Tokens to sell!');
        // lock necessary tokens in the wallet.
        wallet.addLockedToken(msg.sender, amount);
        emit WalletLockToken(msg.sender, amount);

        // if ask price is lower than the highest bid price, can fill order
        uint256 askingPrice = price;
        uint256 highestBidPrice = bid.closest;

        // if there is a bidding price higher than the asking price and order is not fully filled yet.
        while (highestBidPrice != 0 && askingPrice <= highestBidPrice && amount > 0) {

            // get highest bidder 
            OrderList memory orderLst = bid.prices[highestBidPrice];
            // get front and end queue of orders at "highest" price
            uint256 front = orderLst.front;
            uint256 end = orderLst.end;

            // while bid queue at "highest" price is not empty
            while (front < end) {
                // iterating through the bidding orders at "highest" price
                OrderInfo memory orderInfo = orderLst.orders[front];
                uint256 buyerAmount = uint256(orderInfo.amount); // can safely type cast because buy amount is always > 0

                // skip if the bidder has cancelled their bid order
                if (addressOrders[orderInfo.account_address][highestBidPrice] <= 0) {
                    front += 1;
                    continue;
                }

                if (buyerAmount >= amount) {
                    // if a bid order can cover the total ask order

                    // transfer Eth in wallet from buyer to seller.
                    wallet.reduceLockedEth(orderInfo.account_address, amount*highestBidPrice);
                    emit WalletUnlockEth(orderInfo.account_address, amount*highestBidPrice);
                    wallet.transferEth(orderInfo.account_address, msg.sender, amount * highestBidPrice); // amount to transfer = amount sold * price sold at.
                    emit WalletTransferEth(orderInfo.account_address, msg.sender, amount*highestBidPrice);
                    // transfer tokens in wallet from seller to buyer.
                    wallet.reduceLockedToken(msg.sender, amount);
                    emit WalletUnlockToken(msg.sender, amount);
                    wallet.transferToken(msg.sender, orderInfo.account_address, amount);
                    emit WalletTransferToken(msg.sender, orderInfo.account_address, amount);

                    // log sell transaction for ask order fulfilled
                    logTransaction(msg.sender, int256(-amount), highestBidPrice);
                    emit FilledAskOrder(msg.sender, amount, highestBidPrice);
                    // log buy transaction for bid order fulfilled
                    logTransaction(orderInfo.account_address, int256(amount), highestBidPrice);
                    emit FilledBidOrder(orderInfo.account_address, amount, highestBidPrice);
                    buyerAmount -= amount;
                    amount = 0;

                    // update bid orders
                    bid.prices[highestBidPrice].orders[front].amount = int256(buyerAmount);
                    // update addressOrders
                    addressOrders[orderInfo.account_address][highestBidPrice] = int256(buyerAmount);

                    // order has been fulfilled break loop.
                    break;
                } else {
                    // if a bid order can only partially cover the total ask order

                    // transfer Eth in wallet from buyer to seller
                    
                    wallet.reduceLockedEth(orderInfo.account_address, buyerAmount*highestBidPrice);
                    emit WalletUnlockEth(orderInfo.account_address, buyerAmount*highestBidPrice);
                    wallet.transferEth(orderInfo.account_address, msg.sender, buyerAmount * highestBidPrice);
                    emit WalletTransferEth(orderInfo.account_address, msg.sender, buyerAmount*highestBidPrice);
                    
                    // transfer tokens in wallet from seller to buyer
                    wallet.reduceLockedToken(msg.sender, buyerAmount);
                    emit WalletUnlockToken(msg.sender, buyerAmount);
                    wallet.transferToken(msg.sender, orderInfo.account_address, buyerAmount);
                    emit WalletTransferToken(msg.sender, orderInfo.account_address, buyerAmount);

                    // log sell transaction for ask order fulfilled.
                    logTransaction(msg.sender, int256(-buyerAmount), highestBidPrice);
                    emit FilledAskOrder(msg.sender, buyerAmount, highestBidPrice);
                    // log buy transaction for bid order filfilled.
                    logTransaction(orderInfo.account_address, int256(buyerAmount), highestBidPrice);
                    emit FilledBidOrder(orderInfo.account_address, buyerAmount, highestBidPrice);
                    amount -= buyerAmount;
                    buyerAmount = 0;

                    // update bid order that has been filled
                    bid.prices[highestBidPrice].orders[front].amount = 0;
                    // update addressOrders for buyer
                    addressOrders[orderInfo.account_address][highestBidPrice] = 0;
                }
                front += 1;
                
            }

            if (front == end) {
                bid.prices[highestBidPrice].front = 0;
                bid.prices[highestBidPrice].end = 0;
                // get the next "highest" bidding price
                uint256 next = bid.nextClosest[highestBidPrice];
                bid.closest = next;
                delete bid.nextClosest[highestBidPrice];
                highestBidPrice = bid.closest;
            } else {
                bid.prices[highestBidPrice].front = front;
            }
        }

        // if order is not fully fulfilled yet, add to ask orders.
        if (amount > 0) {
            uint256 lowest = ask.closest;

            if (price < lowest || lowest == 0) {
                // if ask price is lower than all the other ask orders.
                ask.nextClosest[price] = ask.closest;
                ask.closest = price;
            
            } else if (price > lowest) {
                // if ask price is NOT lower than all other ask orders.

                uint256 current = lowest;
                uint256 previous;

                // find mapping where by current < price
                while (current < price) {
                    previous = current;
                    current = ask.nextClosest[current];
                    if (current == 0) {
                        break;
                    }
                }
                ask.nextClosest[previous] = price;
                ask.nextClosest[price] = current;
            }

            // add OrderInfo to queue of ask orders with the same ask price
            ask.prices[price].orders.push(OrderInfo({account_address: msg.sender, amount: int256(-amount)}));
            ask.prices[price].end += 1;

            // update address's orders
            addressOrders[msg.sender][price] = int256(-amount);

            emit PlacedAskOrder(msg.sender, amount, price);
        }

        

    }

    function removeAskOrder(uint256 price) public companyOnly {
        require(addressOrders[msg.sender][price] < 0, 'No current Ask orders!');
        uint256 amount = uint256(-addressOrders[msg.sender][price]);
        addressOrders[msg.sender][price] = 0;

        wallet.reduceLockedToken(msg.sender, amount);
        emit WalletUnlockToken(msg.sender, amount);

        emit RemovedAskOrder(msg.sender, amount, price);
    }

    function withdrawToken() public companyOnly {
        require(wallet.getWithdrawableToken(msg.sender) > 0, 'No withdrawable Tokens!');

        uint256 amount = wallet.getWithdrawableToken(msg.sender);
        tokenContract.transfer(address(this), msg.sender, amount);
        wallet.withdrawTokens(msg.sender);

        emit WithdrawToken(msg.sender, amount);


    }

    function withdrawEth() public payable companyOnly {
        require(wallet.getWithdrawableEth(msg.sender) > 0, 'No withdrawable Eth!');

        uint256 amount = wallet.getWithdrawableEth(msg.sender);
        msg.sender.transfer(amount);
        wallet.withdrawEth(msg.sender);

        emit WithdrawEth(msg.sender, amount);

    }
    
}