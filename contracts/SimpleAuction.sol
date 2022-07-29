// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SimpleAuction {
    /* =======================================
        VARIABLES
    =========================================== */

    address payable public beneficiary;
    uint256 public auctionEndTime;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) pendingReturns; // Allowed withdrawal of previous bids

    bool hasEnded;

    /* =======================================
        EVENTS
    =========================================== */
    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    /* =======================================
        ERRORS
    =========================================== */

    /// The auction has already ended
    error AuctionAlreadyEnded();
    /// There is already a higher or equal bid.
    error BidNotHighEnough(uint256 highestBid);
    /// The auction has not ended yet.
    error AuctionNotYetEnded();
    /// The function auctionEnd has already been called.
    error AuctionEndAlreadyCalled();

    /* =======================================
        CONSTRUCTOR
    =========================================== */
    constructor(uint256 biddingTime, address payable beneficiaryAddress) {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }

    /* =======================================
        FUNCTIONS
    =========================================== */

    /**
    @notice External, Payable - Place bid on the contract
     */
    function bid() external payable {
        // Check if auction has ended
        if (block.timestamp > auctionEndTime) {
            revert AuctionAlreadyEnded();
        }

        if (msg.value <= highestBid) {
            revert BidNotHighEnough(highestBid);
        }

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /**
    @notice External - Withdraw a bid
     */
    function withdraw() external returns (bool) {
        // The bid amount previously submitted by msg sender
        uint256 amount = pendingReturns[msg.sender];

        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            // msg.sender is not of type `address payable` and must be explicitly converted using `payable(msg.sender)` in order use the member function `send()`.
            // If payment fails to send, reset the pendingReturns amount
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /**
    @notice External - End the auction and send the highest bid to beneficiary
     */
    function endAuction() external {
        // 1. Conditions
        if (block.timestamp < auctionEndTime) {
            revert AuctionNotYetEnded();
        }
        if (hasEnded) {
            revert AuctionEndAlreadyCalled();
        }

        // 2. Effects
        hasEnded = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. Interaction 
        beneficiary.transfer(highestBid);
    }
}
