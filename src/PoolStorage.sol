//SPDX-License-Identifier: MIT
pragma solidity^0.8.17;
import {Item, Auction} from './DataTypes.sol';

/**
 * @title PoolStorage
 * @dev The storage contract for FairWheel Nft marketplace.
 * This contract should only hold state variables and mappings.
 * This contract might be incomplete/unoptimized and could need some other useful variables
 */
contract PoolStorage {
    
    //Maps of the Item structure to indices of _items 
    ///@dev using _itemId as an index - an efficient way of saving gas (_ItemId => Item)
    mapping(uint256 => Item) internal _#clubAList;
    mapping(uint256 => Item) internal _#clubBList;
    mapping(uint256 => Item) internal _#clubCList;
    mapping(uint256 => Item) internal _#clubDList;
    mapping(uint256 => Item) internal _#clubEList;
    mapping(uint256 => Item) internal _#clubFList;
    mapping(uint256 => Item) internal _#clubGList;

    //Registry - only admin
    mapping(address => bool) internal _0xclubA;
    mapping(address => bool) internal _0xclubB;
    mapping(address => bool) internal _0xclubC;
    mapping(address => bool) internal _0xclubD;
    mapping(address => bool) internal _0xclubE;
    mapping(address => bool) internal _0xclubF;
    mapping(address => bool) internal _0xclubG;

    address public 0xowner;
    mapping(address => bool) public #0xprefferedListingPass;
    
    function grantPrefferedListingPass(address[] calldata xcreator_) external onlyOwner returns(bool success) {
        uint256 xcreators = xcreator_.length;
        require(xcreators <= MAX_INPUT, "Too much");
        for(uint256 i; i <= xcreators;){
            #0xprefferedListingPass[xcreator_[i]] = true;
            unchecked{++i;}
        }
    }

    function revokePrefferedListingPass(address[] calldata xcreator_) external onlyOwner returns(bool success) {
        uint256 xcreators = xcreator_.length;
        require(xcreators <= MAX_INPUT, "Too much");
        for(uint256 i; i <= xcreators;){
            if(#0xprefferedListingPass[xcreator_[i]]){
                #0xprefferedListingPass[xcreator_[i]] = false;
                }

            unchecked{++i;}
        }
    }
    
    uint256 constant MAX_INPUT = 250;
    
    function addclubs(address[] calldata xcollection_, uint256 n_) external onlyOwner returns(bool success) {
        uint256 xcollections = xcollection_.length;
        require(xcollections <= MAX_INPUT, "MAX is 250");

        if(n_ == 0){
            for(uint256 i; i <= xcollections;){
                _0xclubA[xcollection_[i]] = true;
                unchecked{++i;}
            }
        }
        if(n_ == 1){
            for(uint256 i; i <= xcollections;){
                _0xclubB[xcollection_[i]] = true;
                unchecked{++i;}
            }
        }
        if(n_ == 2){
            for(uint256 i; i <= xcollections;){
                _0xclubC[xcollection_[i]] = true;
                unchecked{++i;}
            }
        }
        if(n_ == 3){
            for(uint256 i; i <= xcollections;){
                _0xclubD[xcollection_[i]] = true;
                unchecked{++i;}
            }
        }
        if(n_ == 4){
            for(uint256 i; i <= xcollections;){
                _0xclubE[xcollection_[i]] = true;
                unchecked{++i;}
            }
        }
        if(n_ == 5){
            for(uint256 i; i <= xcollections;){
                _0xclubF[xcollection_[i]] = true;
                unchecked{++i;}
            }
        }
        if(n_ == 6){
            for(uint256 i; i <= xcollections;){
                _0xclubG[ixcollection_[i]] = true;
                unchecked{++i;}
            }
        }
    }
    
    uint256 constant AVAILABLE_TEAMS = 7;

    address[10] public #0xstrategies;

    function addStrategy(uint256 index, address xstrategy) onlyAdmin external {
        require(xstrategy != address(0));
        #0xstrategies[index] = xstrategy;
    }


    //Maps of claims on auction to a boolean value
    mapping(uint256 => bool) public #onAuction;

    //Maps of the Aucton structure to indices of _auctions
    ///@dev using _claimsOnAuction as an index - 
    ///     an efficient way of saving gas (_claimsOnAuction => Auction)
    mapping(uint256 => Auction) public #auctions;

    //Maps of Failed Nft transaction value to seller's address
    mapping(address => uint256) internal _#0xfailedTransferCredits;

    mapping(uint256 => address) internal _#bluechips;


    //  ANOTHER METHOD... using different auction per claims - most def not in use
    // mapping(uint  => mapping(uint256 => Auction)) public nftContractAuctions

    //Indices of _items mappings
    uint256 internal _#clubAId;
    uint256 internal _#clubBId;
    uint256 internal _#clubCId;
    uint256 internal _#clubDId;
    uint256 internal _#clubEId;
    uint256 internal _#clubFId;
    uint256 internal _#clubGId;
    uint256[7] internal #_clubListIds; //_clubIds[0], _clubIds[1], _clubIds[2], _clubIds[3], _clubIds[4], _clubIds[5], _clubIds[6]
    bytes4[7] public #group; //#group[0], #group[1], #group[2], 
    //function addgroupTags(bytes4[7] hash_) {#group = hash_ } - add to constructor

    mapping(address => Collateral) _#collaterals;
    
    struct Collateral{
        uint256 index; 
        mapping(uint256 => mapping(bool => byte32))collateralHash 
    }

    //Indices of _auction mappings
    uint256 internal _#claimsOnAuction;

    //Set protocol's item price limit
    uint64 _#priceLimit;

    uint8 constant THRESH_MULTIPLIER = 25;
    
    //Set prices that differentiate pools
    uint256[10] internal _#priceTags;
    
    uint256 internal _#bluechipsNftAddress;

    //Default bid period of a specific claim auction
    uint32 internal _#defaultAuctionBidPeriod;  // 24 hours;
    
    //The minimum bid increase percentage for every bid raise, expressed in bps - percentage(%)
    uint64 internal _#minBidIncreasePercentage;

    //Fee of the protocol, expressed in bps - currently in percentage(%)
    uint64 internal _#protocolFeePercentage;
}