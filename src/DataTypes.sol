//SPDX-License-Identifier: MIT
pragma solidity^0.8.17;

    enum Status {
        ON_LIST,
        OUT,
        OFF_LIST
    } 
    
    enum Tag { 
        TIER_ONE,   //100 above ethers    100000000000000000000
        TIER_TWO,   //70 - 100 ethers     70000000000000000000     
        TIER_THREE, //50 - 70 ethers      50000000000000000000
        TIER_FOUR,  //35 - 50 ethers      35000000000000000000
        TIER_FIVE,  //20 - 35 ethers      20000000000000000000
        TIER_SIX,   //10 - 20 ethers      10000000000000000000
        TIER_SEVEN, //5 - 10 ethers       5000000000000000000
        TIER_EIGHT, //1 - 5 ethers        1000000000000000000
        TIER_NINE,  //0.5 - 1 ether       0500000000000000000
        BOTTOM_T    //0.01 - 0.5 ether    0010000000000000000
    }

    enum Group {
        A-CLUB,
        B-CLUB,
        C-CLUB,
        D-CLUB,
        E-CLUB,
        F-CLUB,
        INDEPENDENT_PIECE,
        UNIDENTIFIED
    }

    struct Item {
        uint256 tokenId;
        uint128 askPrice;
        uint128 soldPrice;
        Tag label;
        bytes4 clubId;
        //poolStrategy;
        Status status;
        address seller;
       // address rightToClaim;
        address nftRecipient;
        address nftContract;
    }

    struct Auction {
        uint256 highestBid;
        Tag label;
        bytes4 clubId;
        address strategy;
        uint32 auctionTimeLeft;
        address highestBidder;
    }

