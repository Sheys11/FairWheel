//SPDX-License-Identifier: MIT
pragma solidity^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
///@dev would use solmate for gas optimisation later but it's openzeppelin for now for better understanding
//import "@solmate/tokens/ERC721.sol";
//import "@solmate/tokens/ERC20.sol";
import {RandomGenerator} from './RandomGenerator.sol';
import {DataTypes} from './DataTypes.sol';
import {PoolStorage} from './PoolStorage.sol';

error BidFailed(string);

/**
 * @title FairWheel 
 * @dev The main nft marketplace contract where all trades logic are present.
 * This contract should NOT define storage as it is managed by PoolStorage.
 * This contract isn't complete/optimized and should have other useful features like being upgradeable
 */
contract FairWheel is PoolStorage, RandomGenerator {

    IERC20 public _tokenAddress;

    address public _admin;


    modifier ifAdmin() {
        if (msg.sender == _admin) revert();
        _;
    }

/*
=====================================================================================================
============================================= EVENTS ================================================
=====================================================================================================
*/
    event BidSubmitted(
        DataTypes.Tag indexed label, 
        uint256 indexed claimOnBid, 
        uint256 indexed bidAmount, 
        address bidder
    );

    event Deposited(
        uint256 tokenId, 
        uint256 askPrice, 
        uint256 soldPrice, 
        DataTypes.Tag indexed label, 
        DataTypes.Status status, 
        address indexed seller, 
        address rightToClaim, 
        address nftRecipient, 
        address indexed nftContract
    );

    event NewAuctionStarted(
        DataTypes.Tag label, 
        uint256 indexed claimsOnAuction, 
        uint256 indexed auctionTimeLeft, 
        uint256 indexed highestBid, 
        address highestBidder
    );

    event NewBidMade(
        uint8 label, 
        DataTypes.Auction indexed claimsOnAuction, 
        uint256 indexed auctionTimeLeft, 
        uint256 indexed bidAmount, 
        address highestBidder
    );

    event AuctionHasEnded(
        DataTypes.Auction claim
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
        DataTypes.Item indexed item, 
        uint8 indexed label, 
        uint256 indexed claim
    );
    
    event NFTPurchased(
        uint256 tokenId,
        uint256 askPrice,
        uint256 indexed soldPrice,
        DataTypes.Tag label,
        DataTypes.Status status,
        address seller,
        address rightToClaim,
        address indexed nftRecipient,
        address indexed nftContract
    );


    /**
     * @dev The constructor initialises the VRF subscription id from chainlink and an erc20 token address that
     *      that can be accepted aside ether - posssibly WETH. 
     *      Also assigns admin's role to deployer and sets "_defaultAuctionBidPeriod" as 24 hrs.
     * @param tokenAddress_ The erc20 token address
     * @param _subscriptionId Chainlink VRF's subscriptionId
     */
    constructor(IERC20 tokenAddress_, uint64 _subscriptionId) RandomGenerator(_subscriptionId) {
      _tokenAddress = tokenAddress_;
      _admin = msg.sender;
      _defaultAuctionBidPeriod = 86400; // 1 day
    }

/*
=====================================================================================================
=========================================== FUNCTIONS ===============================================
=====================================================================================================
*/

    /**
     * @notice Allows the deposits of NFTs into the pool
     * @dev The current implementation doesn't use the tokenWrapper Nft yet...
     * @param _nftAddress - The address of the NFT
     * @param _tokenId - The Nft's tokenId
     * @param _askPrice - The asking price of a seller
     */
    function sellNFT(
        address _nftAddress, 
        uint256 _tokenId, 
        uint128 _askPrice
    ) public {
        require(_nftAddress != address(0), "INVALID_ADDRESS");
        require(_tokenId != 0, "INVALID_TokenID");
        require(_askPrice >= 1e16, "PRICE_IS_TOO_LOW");
        require(!_deposited[_nftAddress]);

        /// @dev Only whitelisted NFT collection will be allowed to be sold 
        ///      on the protocol - It hasn't been implemented yet 
        //require(whitelistNftAddresses[_nftAddress] = true);
        

        ///@dev If the Nft isn't part of the stored bluechip Nft's addresses,
        ///     the askPrice price must be less than/equal to the average price
        ///     gotten from a Nft oracle  - Hasn't been implemented yet
        /* if(_nftAddress != _bluechips[_nftAddress]) {
            require(_askPrice <= DIAXfloor_MA)
        } */

        IERC721(_nftAddress).transferFrom(
            msg.sender, address(this), _tokenId
        );
        
        
        _deposited[_nftAddress] = true;

        ///@dev The tokenWrapper Nft call - Hasn't been implemented yet
        //_mintbeeCard(uint _askPrice);

        DataTypes.Tag label;

        uint256 deposit = _itemId;

        _items[deposit] = DataTypes.Item(
            _tokenId,
            _askPrice,
            0,
            label,
            DataTypes.Status.OFF_LIST,
    //        beeCardId,
            payable(msg.sender),
            payable(0),
            payable(0),
            _nftAddress
        );

        //this must update the struct
        label = _addLabel(deposit);

        _itemId++;

        emit Deposited(
            _tokenId, 
            _askPrice, 
            0, 
            label, 
            DataTypes.Status.OFF_LIST, 
            payable(msg.sender), 
            payable(0), 
            payable(0), 
            _nftAddress
        );
    }


    /**
     * @notice Starts a new auction
     * @dev Check for any excess of memory/gas used. Function is made public so any contract can call it
     * @param _label - The specific label(pool) to bid from
     */
    function startNewAuction(DataTypes.Tag _label) public {
    
        uint256 i; uint256 j;

        //declared an "offList" array to store the Ids of items 
        //with the "_label" and "OFF_LIST" tags
        uint256[] memory offList = new uint[](j);

        while(i < _itemId){
            DataTypes.Item memory item = _items[i];
            if(item.label == _label){
                if(item.status == DataTypes.Status.OFF_LIST){
                    offList[j] = i;
                    j++;
                } 
            }

            unchecked {
                i++;
            }
        }

        uint256 floorPrice = _getFloorPrice(_label);
        
        (bool approved) = IERC20(_tokenAddress).approve(
            address(this), floorPrice
        );
        require(approved);
        
        uint256 rand = RandomGenerator.generateRandomObject(
            address(this), offList
        ); 

        _items[rand].status = DataTypes.Status.ON_LIST;

        _auctions[_claimsOnAuction] = DataTypes.Auction({
            highestBid: floorPrice,
            label: _label,
            auctionTimeLeft: _defaultAuctionBidPeriod,
            highestBidder: payable(msg.sender)
        });
        
        _onAuction[_claimsOnAuction] = true; 

        _claimsOnAuction++;

        emit NewAuctionStarted(
            _label, 
            _claimsOnAuction, 
            _auctions[_claimsOnAuction].auctionTimeLeft, 
            _auctions[_claimsOnAuction].highestBid, 
            msg.sender
        );
    }

    
    /**
     * @notice Allows buyers to bid for a claim to an Nft
     * @dev Check for any excess of memory/gas used. Function is made public so any contract can call it
     * @param _label - The specific label(pool) to bid from
     * @param _claimToBidOn The specific claim to bid on
     * @param _bidAmount The bid price user is willing to pay
     */
    function bidForClaims(
        uint8 _label, 
        uint256 _claimToBidOn, 
        uint256 _bidAmount
    ) public {
        require(_bidAmount != 0, "INVALID_INPUT");
        require(_onAuction[_claimToBidOn] = true, "ITEM_NOT_ON_AUCTION");

        DataTypes.Auction storage claim = _auctions[_claimToBidOn];
        
        require(uint8(claim.label) == _label, "WRONG_POOL");
        
        ///@dev Checks if auction is still on - Auction time is 24 hrs
        uint32 timeLeft = _timeLeft(_claimToBidOn);

        if(timeLeft != 0){
            //Bid amount must meet the minimum bid increase 
            // percentage of current claim
            require((_bidAmount - claim.highestBid) >= (
                claim.highestBid * _minBidIncreasePercentage
                ), "YOUR_BID_IS < _minBidIncreasePercentage_OF_CURRENT_BID"
            );
            
            (bool done) = IERC20(_tokenAddress).approve(
                address(this), _bidAmount
            );
            require(done);

            claim.highestBid = _bidAmount;
            claim.highestBidder = msg.sender;

       
            emit NewBidMade(
                _label, 
                claim, 
                timeLeft, 
                _bidAmount, 
                msg.sender
            );
        } 
        
        revert BidFailed("AUCTION_HAS_ENDED");
    }    


    /**
     * @notice Assigns claiming rights to random itemIds
     * @dev Check if there's any excess use of memory/gas
     * @param _label The pool label in an uint
     */
    function assignClaimingRights(uint8 _label) public {
        uint256 index;
        while(index < _claimsOnAuction){
            if(uint8(_auctions[index].label) == _label){
                if(_timeLeft(index) == 0){
                    uint256 randomId = _deliverItem(_label);
                    DataTypes.Item storage item = _items[randomId];
                    DataTypes.Auction memory claim = _auctions[index];

                    item.rightToClaim = claim.highestBidder;
                    item.soldPrice = claim.highestBid;
                    item.status = DataTypes.Status.OUT;
                }
            }

            unchecked {
                index++;  
            }
        }

        emit ClaimingRightsAssigned(
            _label
        );
    }


    ///@notice Allows highest bidder to claim their Nft
    ///@dev Check if there's any excess use of memory/gas
    ///@param _label The pool label in an uint
    ///@param _claim The Id of the auction won
    ///@param _nftRecipient A recipient address where the Nft would be transferred to
    function claimNft(
        uint8 _label, 
        uint256 _claim, 
        address _nftRecipient
    ) external {
        DataTypes.Auction memory claim = _auctions[_claim];
        require(msg.sender == claim.highestBidder, "WRONG_AUCTION_ID");
        assignClaimingRights(_label);

        uint256 i;
        while(i < _itemId){
            DataTypes.Item storage item = _items[i];

            if(uint8(_items[i].label) == _label && 
            item.status == DataTypes.Status.OUT){
                
                if(item.rightToClaim == claim.highestBidder && 
                item.soldPrice == claim.highestBid){
                    
                    (bool checked) = IERC20(_tokenAddress).approve(
                        address(this), item.soldPrice
                    );
                    require(checked);
                    
                    _purchaseItem(i, _nftRecipient);
                    _resetAll(i, _claim);
                    
                    break;
                }
            }

            unchecked {
                i++;  
            }
        }

        emit NftWithdrawn(
            _items[i], 
            _label, 
            _claim
        );
    }

/*
=====================================================================================================
======================================= INTERNAL FUNCTIONS ==========================================
=====================================================================================================
*/

    ///@notice Adds a pool label to Nft according to the askPrice
    ///@dev An "if" statement seems the best way to set this. 
    ///     need to save gas too - current gas is almost 94k
    ///@param _item - The address of the NFT
    ///@return item.label - the assigned label
    function _addLabel(uint256 _item) internal returns(DataTypes.Tag){
        DataTypes.Item storage item = _items[_item];
 
        if(item.askPrice < _priceTags[0]){
            if(item.askPrice >= _priceTags[1]){
                item.label = DataTypes.Tag.TIER_TWO;  
            } else if(item.askPrice >= _priceTags[2]){
                item.label = DataTypes.Tag.TIER_THREE;
            } else if(item.askPrice >= _priceTags[3]){
                item.label = DataTypes.Tag.TIER_FOUR;
            } else if(item.askPrice >= _priceTags[4]){
                item.label = DataTypes.Tag.TIER_FIVE;
            } else if(item.askPrice >= _priceTags[5]){
                item.label = DataTypes.Tag.TIER_SIX;
            } else if(item.askPrice >= _priceTags[6]){
                item.label = DataTypes.Tag.TIER_SEVEN;
            } else if(item.askPrice >= _priceTags[7]){
                item.label = DataTypes.Tag.TIER_EIGHT;
            } else if(item.askPrice >= _priceTags[8]){
                item.label = DataTypes.Tag.TIER_NINE;
            } else if(item.askPrice >= _priceTags[9]){
                item.label = DataTypes.Tag.BOTTOM_T;
            }
        }
        
        item.label = DataTypes.Tag.TIER_ONE;

        return item.label;
    }

    
    ///@dev Checks if auction is still on - Auction time is 24 hrs
    ///     The wrapped block.timestamp in uint32 only compares with the first 4 bytes 
    ///     of the entire timestamp. Not sure if that really makes it fair - if every sec
    ///     should count!
    ///     But the "if" statement code line had that in check. Hence the rational "<" instead of "<="
    function _timeLeft(uint256 _claim) internal returns(uint32) {
        DataTypes.Auction storage claim = _auctions[_claim];
        
        if(claim.auctionTimeLeft < uint32(block.timestamp)){
            _onAuction[_claim] = false;
            
            emit AuctionHasEnded(claim);
        
            return claim.auctionTimeLeft = 0;
        } 

        uint32 timeleft = claim.auctionTimeLeft - uint32(block.timestamp);

        return claim.auctionTimeLeft = timeleft;
    }


    ///@dev Loops through all items on/off auction in a pool and calculates the average price
    ///     Calculation still need a math library to avoid rounded figures
    ///@param _label The pool label
    ///@return floorPrice The average price of an Nft from the pool
    function _getFloorPrice(DataTypes.Tag _label) private view returns(uint256){
       uint256 i; uint256 num; uint256 amount;
       while(i < _itemId){
        DataTypes.Item memory item = _items[i];
        if(item.label == _label){
            if(item.status == DataTypes.Status.OFF_LIST){
                num = num + 1;
                amount = amount + item.askPrice;
            }
            
            while(i < _claimsOnAuction){
                DataTypes.Auction memory claim = _auctions[i];
                if(claim.label == _label){
                    num = num + 1;
                    amount = amount + claim.highestBid;
                }
                
                unchecked {
                    i++;
                }
            }
        }
        
        unchecked {
            i++;
        }
       }

       uint256 floorPrice = (amount / num);
       
       return floorPrice;
    }

    ///@notice Generates a random itemId through the RandomGenerator
    ///@dev Check if there's any excess use of memory/gas
    function _deliverItem(uint8 _label) internal returns(uint256) {
        uint256 i; uint256 j; 
        
        uint256[] memory itemsList = new uint[](j);

        while(i < _itemId){
            if(uint8(_items[i].label) == _label){
                if(_items[i].status == DataTypes.Status.ON_LIST){
                    itemsList[j] = i;
                    j++;
                }
            }

            unchecked {
                i++;  
            }
        }

        uint256 rand = RandomGenerator.generateRandomObject(
            address(this), itemsList
        );

        // a placeholder to remove objects if random generator inheritance doesn't work during tests
        //remove(objects[objectId]);

        return rand;
    } 


    ///@notice Makes the purchase of an item
    ///@dev Check if there's any excess use of memory/gas
    ///@param _item The Id of the item to purchase
    ///@param _nftRecipient A recipient address where the Nft would be transferred to
    function _purchaseItem(
        uint256 _item, 
        address _nftRecipient
    ) internal {
        DataTypes.Item storage item = _items[_item];

        item.nftRecipient = _getNftRecipient(_item, _nftRecipient);

        _payFeeAndSeller(item);

        ///@dev Uses safeTransferFrom to check if "item.nftRecipient" 
        ///     can receive Nft before execution
        IERC721(item.nftContract).safeTransferFrom(
            address(this),
            item.nftRecipient,
            item.tokenId
        );

        _deposited[item.nftContract] = false;

       // _resetAll(item);

        emit NFTPurchased(
            item.tokenId,
            item.askPrice,
            item.soldPrice,
            item.label,
            item.status,
            item.seller,
            item.rightToClaim,
            item.nftRecipient,
            item.nftContract
        );
    }

    function _payFeeAndSeller(DataTypes.Item memory _item) internal {
        
        uint256 fee = _getPortionOfBid(_item.soldPrice);

        _payout(_item, (_item.soldPrice - fee));
    }


    /// @dev Originally, it should be paid to the BeeCard - token wrapper NFT(ERC1155) 
    ///      But it hasn't been implemented yet.
    function _payout(
        DataTypes.Item memory _item, 
        uint256 _amount
    ) internal {
        
        //    payable(msg.sender).approve(address(this), _tokenAddress)_item.BeeCardId);
        
        // An ETH call - attempt to send the funds to the recipient
        (bool success, ) = payable(_item.seller).call{
            value: _amount,
            gas: 20000
        }("");
        
        //if it fails, send to this contract 
        if (!success) {
            (bool sent, ) = payable(address(this)).call{
                value: _amount,
                gas: 20000
            }("");

        //if it fails, try an erc20 token(WETH) || send it to this contract 
        if (!sent) {
            (bool paid) = IERC20(_tokenAddress).transferFrom(
                msg.sender, _item.seller, _amount) || IERC20(
                    _tokenAddress).transfer(address(this), _amount
                );
                require(paid);
            }
        }

        //    burn(_item.BeeCardId);

        //Update their credit on the contract so they can pull it later
        _failedTransferCredits[_item.seller] = _failedTransferCredits[_item.seller] + _amount;
    }

    function _resetAll(
        uint256 _itemIndex, 
        uint256 _claimIndex
    ) internal {
       _removeItem(_itemIndex);
       _removeClaim(_claimIndex);
    }
    
    /**
     * @notice Removes an index of the "_items" mappings
     * @dev An index of the "_items" mappings is shifted to the last index.
     *      The last index which holds the new value gets deleted.
     *      And the total indices gets decremented by 1.
     * @param _index The index of the "_items" mappings from the indices - "_itemId"
     */
    function _removeItem(uint _index) internal {
        uint i = _index;
        while(i < _itemId){
            _items[i] = _items[i + 1]; 
            
            unchecked {
                i++;  
            }
            
            delete _items[i];

           _itemId = _itemId - 1; 
        }   
    } 

    function _removeClaim(uint _index) internal {
        uint i = _index;
        while(i < _claimsOnAuction - 1){
           _auctions[i] = _auctions[i + 1]; 
            unchecked {
                i++;  
            }
           delete _auctions[i];
          // _claimsOnAuction = _claimsOnAuction - 1; 
        }   
    } 

/*
=====================================================================================================
============================================= SETTERS ===============================================
=====================================================================================================    
*/    

    ///@dev Only Admin can update priceTag 
    ///@return _priceTag
    function setPriceTag(
        uint8 _priceTagId, 
        uint256 _value
    ) ifAdmin external returns(uint256) {
        require(_value != 0, "INVALID_INPUT");
        _priceTags[_priceTagId] = _value * 1e18;
        return _priceTags[_priceTagId];
    }
    
    function setDefaultBidPeriod(uint256 _newTime) ifAdmin external {
        _defaultAuctionBidPeriod = uint32(_newTime * 1 hours);
        emit DefaultBidPeriodUpdated(_defaultAuctionBidPeriod);
    }

    function setMinBidIncreasePercentage(uint64 _num) ifAdmin external {
        require(_num <= 100);
        _minBidIncreasePercentage = _num / 100;
        emit MinBidIncreasePercentageUpdated(_minBidIncreasePercentage);
    }

    function setProtocolFeePercentage(uint64 _num) ifAdmin external {
        require(_num <= 100);
        _protocolFeePercentage = _num / 100;
        emit ProtocolFeePercentageUpdated(_protocolFeePercentage);
    }

    function setAdmin(address _newAdmin) external ifAdmin {
        require(_newAdmin != address(0), " INVALID_INPUT");
        //_setAdmin(_newAdmin);
        _admin = _newAdmin;
        emit AddedAdmin(_newAdmin);
    }

/*
=====================================================================================================
============================================= GETTERS ===============================================
=====================================================================================================
*/
    /*
     * The default value for the NFT recipient is the highest bidder
     */
    function _getNftRecipient(
        uint256 _item, 
        address _nftRecipient
    ) internal view returns(address) {
        if (_nftRecipient == address(0)) {
            return _items[_item].rightToClaim;
        } 
        
        return _nftRecipient;
    }

    function _getPortionOfBid(uint256 _soldPrice) internal view returns(uint256) {
        return _soldPrice * _protocolFeePercentage;
    }

    function getClaimBidTimeLeft(uint256 _claimOnBid) external returns(uint32) {
        return _timeLeft(_claimOnBid);
    }

    function getFloorPrice(DataTypes.Tag _label) public view returns(uint256){
        return _getFloorPrice(_label);
    }
    
    function _getMinBidIncreasePercentage() internal view returns (uint64) {
        return _minBidIncreasePercentage;
    } 

    function getAuctionBidPeriod() public view returns (uint32){
        return _defaultAuctionBidPeriod;
    }

} 
