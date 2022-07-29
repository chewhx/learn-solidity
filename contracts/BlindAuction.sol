// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/// @title Blind Auction
/// @notice Bidders send in hashed version of their bids with the money. At the end of the bid, they will resend the unhashed version which will be matched against the hashed versions in the contract.

contract BlindAuction {
    /* =======================================
      VARIABLES
    =========================================== */
    struct Bid {
        bytes32 blindedBid;
        uint256 deposit;
    }

    address payable public beneficiary;
    uint256 public biddingEnd;
    uint256 public revealEnd;
    bool public hasEnded;

    mapping(address => Bid[]) public bids;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address => uint256) pendingReturns;

    event AuctionEnded(address winner, uint256 highestBid);

    /* =======================================
        ERRORS
    =========================================== */
    error TooEarly(uint256 time);
    error TooLate(uint256 time);
    error AuctionEndAlreadyCalled();

    /* =======================================
        MODIFIERS
    =========================================== */
    modifier onlyBefore(uint256 time) {
        if (block.timestamp >= time) revert TooLate(time);
        _;
    }

    modifier onlyAfter(uint256 time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }

    /* =======================================
        CONSTRUCTOR
    =========================================== */
    constructor(
        uint256 biddingTime,
        uint256 revealTime,
        address payable beneficiaryAddress
    ) {
        beneficiary = beneficiaryAddress;
        biddingEnd = block.timestamp + biddingTime;
        revealEnd = biddingTime + revealTime;
    }

    /* =======================================
        FUNCTIONS
    =========================================== */
    function bid(bytes32 blindedBid) external payable onlyBefore(biddingEnd) {
        bids[msg.sender].push(
            Bid({blindedBid: blindedBid, deposit: msg.value})
        );
    }

    /**
    @notice Reveal blinded bids and get refund for all the correctly blinded losing bids.
     */
    function reveal(
        uint256[] calldata values,
        bool[] calldata fakes,
        bytes32[] calldata secrets
    ) external onlyAfter(biddingEnd) onlyBefore(revealEnd) {
        // Number of bids by sender
        uint256 numBids = bids[msg.sender].length;

        // Require the params length match the number of bids
        require(values.length == numBids);
        require(fakes.length == numBids);
        require(secrets.length == numBids);

        // Declare refund variable
        uint256 refund;

        // Loop through the bids
        for (uint256 i = 0; i < numBids; i++) {
            // For each bid
            Bid storage bidToCheck = bids[msg.sender][i];

            // Extract vale, fake, secret from function params submitted by sender
            (uint256 value, bool fake, bytes32 secret) = (
                values[i],
                fakes[i],
                secrets[i]
            );

            // Match blinded bid hash against hash of the submitted params
            // If they do not match, it's an invalid bid, continue and do not refund
            if (
                bidToCheck.blindedBid !=
                keccak256(abi.encodePacked(value, fake, secret))
            ) {
                // `continue` will skip the remaining block of code and start the next loop iteration
                continue;
            }

            // If the hash of params match the blinded bid by sender, add the deposit to refund variable
            refund += bidToCheck.deposit;

            //
            if (!fake && bidToCheck.deposit >= value) {
                if (placeBid(msg.sender, value)) {
                    refund -= value;
                }
                bidToCheck.blindedBid = bytes32(0);
            }

            payable(msg.sender).transfer(refund);
        }
    }

    /**
    @notice Withdraw a bid that was overbid
     */
    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    /**
    @notice Set auction to end and transfer the bid to beneficiary. Can only be called once.
     */
    function auctionEnd() external onlyAfter(revealEnd) {
        // 1. Conditions
        // If `hadEnded` is true, means this function has already been called, and the auction end has been effected.
        if (hasEnded) {
            revert AuctionEndAlreadyCalled();
        }

        // 2. Effects
        emit AuctionEnded(highestBidder, highestBid);
        hasEnded = true;
        beneficiary.transfer(highestBid);
    }

    /**
    @notice Place bid
    @param bidder Bidder's address 
    @param value Bid value 
    @return success Boolean indicating whether bid is successfully
     */
    function placeBid(address bidder, uint256 value)
        internal
        returns (bool success)
    {
        // 1. Conditions
        // The value of the bid must be highest than the current highest bid
        if (value <= highestBid) {
            return false;
        }

        // 2. Effects
        // If the highestBidder is not an empty address
        // OR: If there is currently a highest bidder
        if (highestBidder != address(0)) {
            // Set his bid to pending returns
            pendingReturns[highestBidder] += highestBid;
        }

        highestBid = value;
        highestBidder = bidder;
        return true;
    }
}
