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

    function depositToken(uint256 amount) public {
        tokenContract.transfer(msg.sender, address(this), amount);
        wallet.depositTokens(msg.sender, amount);
    }

    function placeBidOrder(uint256 amount, uint256 price) public payable {
        
        // update balance of eth in wallet
        wallet.depositEth(msg.sender, msg.value);
        // ensure there is no other ask orders at this price
        require(addressOrders[msg.sender][price] >= 0, 'Currently have ask order at this price!');
        // ensure that there is sufficient funds in wallet to make the purchase
        uint256 availableEth = wallet.getWithdrawableEth(msg.sender);
        require(availableEth >= amount * price, 'Insufficient funds! Please top up!');
        // lock necessary eth in the wallet.
        wallet.addLockedEth(msg.sender, amount*price);

        // if bid price is higher than the lowest ask price, can fill order.
        uint256 lowest = ask.closest;
        // uint256 total = amount;

        // if there is a asking price lower than the bidding price and order is not fully filled yet
        while (price >= lowest && amount > 0) {
            OrderList memory orderLst = ask.prices[price];
            uint256 front = orderLst.front;
            uint256 end = orderLst.end;
            
            // while ask queue at "lowest" price is not empty
            while (front < end) {
                // iterating through the asking orders at "lowest" price.
                OrderInfo memory orderInfo = orderLst.orders[front];
                uint256 sellerAmount = orderInfo.amount >= 0 ? uint256(orderInfo.amount) : uint256(-orderInfo.amount);
                
                // skip if the seller has cancelled the ask order.
                if (addressOrders[orderInfo.account_address][lowest] >= 0) {
                    front += 1;
                    continue;
                }

                if (sellerAmount >= amount) {
                    // if a ask order can cover the total bid order
                    
                    // transfer Eth in wallet
                    wallet.reduceLockedEth(msg.sender, amount * lowest);
                    wallet.transferEth(msg.sender, orderInfo.account_address, amount * lowest);
                    // transfer tokens in wallet
                    wallet.transferToken(orderInfo.account_address, msg.sender, amount);
                    
                    // Log sell transaction for ask order fulfilled.
                    logTransaction(orderInfo.account_address, int256(-amount), lowest);
                    // log buy transaction for bid order fulfilled.
                    logTransaction(msg.sender, int256(amount), lowest);

                    sellerAmount -= amount;
                    amount = 0;

                    // order has been fulfilled break loop.
                    break;
                } else {
                    // if a ask order can only partially cover the total bid order

                    // transfer Eth in wallet
                    wallet.reduceLockedEth(msg.sender, sellerAmount * lowest);
                    wallet.transferEth(msg.sender, orderInfo.account_address, sellerAmount * lowest);
                    // transfer tokens in wallet
                    wallet.transferToken(orderInfo.account_address, msg.sender, sellerAmount);
                    
                    // Log sell transaction for ask order fulfilled
                    logTransaction(orderInfo.account_address, int256(-sellerAmount), lowest);
                    // log buy transaction for bid order fulfilled.
                    logTransaction(msg.sender, int256(sellerAmount), lowest);

                    amount -= sellerAmount;
                    sellerAmount = 0;
                    uint256 next = ask.nextClosest[lowest];
                    ask.closest = next;
                    delete ask.nextClosest[lowest];
                }
                orderInfo.amount -= int256(-sellerAmount);
                front += 1;
            }
            orderLst.front = front;
            lowest = ask.closest;
        }

        // reduce restricted eth in wallet, since partial of the bid order has been fulfilled.
        // if (total > amount) {
        //     uint256 ethUnlocked = (total - amount) * price;
        //     wallet.reduceLockedEth(msg.sender, ethUnlocked);
        // }
        
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
        }
    }

    function removeBidOrder(uint256 price) public {
        require(addressOrders[msg.sender][price] > 0, 'No current Bid orders!');
        addressOrders[msg.sender][price] = 0;
    }

    function placeAskOrder(uint256 amount, uint256 price) public {
        // ensure there is no other bidOrders at this price.
        require(addressOrders[msg.sender][price] <= 0, 'Currently have bid order at this price!');
        // ensure there is sufficient tokens in wallet to make the purchase
        require(wallet.getWithdrawableToken(msg.sender) >= amount, 'Insufficient Tokens to sell!');
        // lock necessary tokens in the wallet.
        wallet.addLockedToken(msg.sender, amount);

        // if ask price is lower than the highest bid price, can fill order
        uint256 highest = bid.closest;
        // uint256 total = amount;

        // if there is a bidding price higher than the asking price and order is not fully filled yet.
        while (price <= highest && amount > 0) {

            OrderList memory orderLst = bid.prices[price];
            uint256 front = orderLst.front;
            uint256 end = orderLst.end;

            // while bid queue at "highest" price is not empty
            while (front < end) {
                // iterating through the bidding orders at "highest" price
                OrderInfo memory orderInfo = orderLst.orders[front];
                uint256 buyerAmount = uint256(orderInfo.amount); // can safely type cast because buy amount is always > 0

                // skip if the bidder has cancelled their bid order
                if (addressOrders[orderInfo.account_address][highest] <= 0) {
                    front += 1;
                    continue;
                }

                if (buyerAmount >= amount) {
                    // if a bid order can cover the total ask order

                    // transfer Eth in wallet from buyer to seller.
                    wallet.transferEth(orderInfo.account_address, msg.sender, amount * highest); // amount to transfer = amount sold * price sold at.

                    // transfer tokens in wallet from seller to buyer.
                    wallet.reduceLockedToken(msg.sender, amount);
                    wallet.transferToken(msg.sender, orderInfo.account_address, amount);

                    // log sell transaction for ask order fulfilled
                    logTransaction(msg.sender, int256(-amount), highest);

                    // log buy transaction for bid order fulfilled
                    logTransaction(orderInfo.account_address, int256(amount), highest);

                    buyerAmount -= amount;
                    amount = 0;

                    // order has been fulfilled break loop.
                    break;
                } else {
                    // if a bid order can only partially cover the total ask order

                    // transfer Eth in wallet from buyer to seller
                    wallet.transferEth(orderInfo.account_address, msg.sender, buyerAmount * highest);
                    // transfer tokens in wallet from seller to buyer
                    wallet.reduceLockedToken(msg.sender, buyerAmount);
                    wallet.transferToken(msg.sender, orderInfo.account_address, buyerAmount);

                    // log sell transaction for ask order fulfilled.
                    logTransaction(msg.sender, int256(-buyerAmount), highest);
                    // log buy transaction for bid order filfilled.
                    logTransaction(orderInfo.account_address, int256(buyerAmount), highest);

                    amount -= buyerAmount;
                    buyerAmount = 0;
                    uint256 next = bid.nextClosest[highest];
                    bid.closest = next;
                    delete bid.nextClosest[highest];
                }
                orderInfo.amount = int256(buyerAmount);
                front += 1;
                
            }

            orderLst.front = front;
            highest = bid.closest;
        }

        // reduce restricted token in wallet since partial of the bid order has been fulfilled.
        // if (total > amount) {
        //     uint256 tokensUnlocked = total - amount;
        //     wallet.reduceLockedToken(msg.sender, tokensUnlocked);
        // }

        // if order is not fully fulfilled yet, add to ask orders.
        if (amount > 0) {
            uint256 lowest = ask.closest;

            if (price < lowest) {
                // if ask price is lower than all the other ask orders.

                ask.nextClosest[price] = ask.closest;
                ask.closest = price;
            
            } else {
                // if ask price is NOT lower than all other ask orders.

                uint256 current = lowest;
                uint256 previous;

                // find mapping where by current < price
                while (current < price) {
                    previous = current;
                    current = ask.nextClosest[current];
                }
                ask.nextClosest[previous] = price;
                ask.nextClosest[price] = current;
            }
        }

        // add OrderInfo to queue of ask orders with the same ask price
        ask.prices[price].orders.push(OrderInfo({account_address: msg.sender, amount: int256(-amount)}));
        ask.prices[price].end += 1;

        // update address's orders
        addressOrders[msg.sender][price] = int256(-amount);

    }

    function removeAskOrder(uint256 price) public {
        require(addressOrders[msg.sender][price] < 0, 'No current Ask orders!');
        addressOrders[msg.sender][price] = 0;
    }



    
}