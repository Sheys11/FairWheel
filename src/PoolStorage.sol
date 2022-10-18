//SPDX-License-Identifier: MIT
pragma solidity^0.8.17;
import {DataTypes} from './DataTypes.sol';

/**
 * @title PoolStorage
 * @dev The storage contract for FairWheel Nft marketplace.
 * This contract should only hold state variables and mappings.
 * This contract might be incomplete/unoptimized and could need some other useful variables
 */
contract PoolStorage {
    //Maps of the Item structure to indices of _items 
    ///@dev using _itemId as an index - an efficient way of saving gas (_ItemId => Item)
    mapping(uint256 => DataTypes.Item) internal _items;

    //Maps of deposited NftAddress to a boolean value 
    mapping(address => bool) internal _deposited;

    //Maps of claims on auction to a boolean value
    mapping(uint256 => bool) internal _onAuction;

    //Maps of the Aucton structure to indices of _auctions
    ///@dev using _claimsOnAuction as an index - 
    ///     an efficient way of saving gas (_claimsOnAuction => Auction)
    mapping(uint256 => DataTypes.Auction) internal _auctions;

    //Maps of Failed Nft transaction value to seller's address
    mapping(address => uint256) internal _failedTransferCredits;

    mapping(address => uint256) internal _bluechips;


    //  ANOTHER METHOD... using different auction per claims - most def not in use
    // mapping(uint  => mapping(uint256 => Auction)) public nftContractAuctions

    //Indices of _items mappings
    uint256 internal _itemId;

    //Indices of _auction mappings
    uint256 internal _claimsOnAuction;
    
    //Set prices that differentiate pools
    uint256[10] internal _priceTags;
    
    uint256 internal _bluechipsNftAddress;

    //Default bid period of a specific claim auction
    uint32 internal _defaultAuctionBidPeriod;  // 24 hours;
    
    //The minimum bid increase percentage for every bid raise, expressed in bps - percentage(%)
    uint64 internal _minBidIncreasePercentage;

    //Fee of the protocol, expressed in bps - currently in percentage(%)
    uint64 internal _protocolFeePercentage;
}