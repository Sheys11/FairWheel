// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {FairWheel} from "../FairWheel.sol";
import {RandomGenerator} from '../RandomGenerator.sol';
import {Status, Tag, Item, Auction} from '../DataTypes.sol';
//import {IVault} from "src/interfaces/IVault.sol";

contract HelperEvents {
    // FairWheeel events
    event BidSubmitted(
        Tag indexed label, 
        uint256 indexed claimOnBid, 
        uint256 indexed bidAmount, 
        address bidder
    );

    event NFTDeposited(
        uint256 tokenId, 
        uint256 askPrice, 
        uint256 soldPrice, 
        Tag indexed label, 
        Status status, 
        address indexed seller, 
        address rightToClaim, 
        address nftRecipient, 
        address indexed nftContract
    );

    event NewAuctionStarted(
        Tag label, 
        uint256 indexed claimsOnAuction, 
        uint256 indexed auctionTimeLeft, 
        uint256 indexed highestBid, 
        address highestBidder
    );

    event NewBidMade(
        uint8 label, 
        Auction indexed claimsOnAuction, 
        uint256 indexed auctionTimeLeft, 
        uint256 indexed bidAmount, 
        address highestBidder
    );

    event AuctionHasEnded(
        Auction claim
    );

    event DefaultBidPeriodUpdated(
        uint32 defaultAuctionBidPeriod
    );

    event MinBidIncreasePercentageUpdated(
        uint64 minBidIncreasePercentage
    );

    event ProtocolFeePercentageUpdated(
        uint64 protocolFeePercentage
    );

    event AddedAdmin(
        address newAdmin
    );

    event ClaimingRightsAssigned(
       uint8 label
    );

    event NftWithdrawn(
        Item indexed item, 
        uint8 indexed label, 
        uint256 indexed claim
    );
    
    event NFTPurchased(
        uint256 tokenId,
        uint256 askPrice,
        uint256 indexed soldPrice,
        Tag label,
        Status status,
        address seller,
        address rightToClaim,
        address indexed nftRecipient,
        address indexed nftContract
    );

    event FundsReceived(
        address sender, 
        uint256 amount
    );
}