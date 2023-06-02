//SPDX_License-identifier: MIT
pragma solidity^0.8.17;
import {RandomGenerator} from '../../RandomGenerator.sol';
import {Status, Tag, Item, Auction} from '../../DataTypes.sol';
import {PoolStorage} from '../../PoolStorage.sol';

//error BidFailed(string);

/**
 * @title FairWheel Marketplace
 * @dev The main nft marketplace contract where all trades logic are present.
 * This contract should NOT define storage as it is managed by PoolStorage.
 * This contract isn't complete/optimized and should have other useful features like being upgradeable
 */
abstract contract Tier1Strategy is PoolStorage, RandomGenerator {
    
    /*
    uint32 constant PROTOCOL_FEE = 1500;

 //   uint256 PRICE_LIMIT = 100e18;

    uint32 constant MINIMUM_BID_INCREASE_PERCENTAGE; //= 100; 100, 80, 85, 70 50, 55, 30, 

    uint32 constant BID_INCREASE_RATE; // = 50; 100


    function resetMechanism(uint32 _bidPercent, ) internal return {
        if(claimsOnAuction >= itemIds.label)

        _auctions[claimsOnAuction].label > 10million + 1million 100,000
    }

    /**
     * @notice Starts a new auction
     * @dev Check for any excess of memory/gas used. Function is made public so any contract can call it
     * @param _label - The specific label(pool) to bid from
     */ /*
    function startNewAuction(Tag _label, bytes param) public {
    
        uint256 i; uint256 j;

        //declared an "offList" array to store the Ids of items 
        //with the "_label" and "OFF_LIST" tags
        uint256[] memory offList = new uint256[](j);

        while(i < _itemId){
            Item memory item = _items[i];
            if(item.label == _label){
                if(item.status == Status.OFF_LIST){
                    offList[j] = i;
                    j++;
                } 
            }

            unchecked {
                i++;
            }
        }

        uint256 floorPrice = _getFloorPrice(_label);

        //address(0).safeApprove(floorPrice);
        //payable(msg.sender).safeApprove(address(this), floorPrice);
        uint256 userBalance = payable(msg.sender).balance;
        
        if(userBalance < floorPrice){
            weth.safeApprove(address(this), floorPrice);
        }
        /*
        
        (bool approved) = IERC20(_tokenAddress).approve(
            address(this), floorPrice
        );
        require(approved);
        */
 /*
        uint256 rand = RandomGenerator.generateRandomObject(
            msg.sender, offList
        ); 

        _items[rand].status = Status.ON_LIST;
        if(_label == Tag.TIER_ONE && _lebel == Tag.TIER_TWO){
            param = _items[rand].tokendata;
            ERC721(item.nftContract).tokenURI(item.tokenId);


        }

        _auctions[_claimsOnAuction] = Auction({
            highestBid: floorPrice,
            label: _label,
            auctionTimeLeft: _defaultAuctionBidPeriod,
            highestBidder: payable(msg.sender)
            param: " "
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

    function fetchRate() internal override returns(uint256){
        
    }
    
    /**
     * @notice Allows buyers to bid for a claim to an Nft
     * @dev Check for any excess of memory/gas used. Function is made public so any contract can call it
     * @param _label - The specific label(pool) to bid from
     * @param _claimToBidOn The specific claim to bid on
     * @param _bidAmount The bid price user is willing to pay
     */
   /* function bidForClaims(
        uint8 _label, 
        uint256 _claimToBidOn, 
        uint256 _bidAmount
    ) public {
        require(_bidAmount != 0, "INVALID_INPUT");
        require(_onAuction[_claimToBidOn] == true, "ITEM_NOT_ON_AUCTION");

        Auction storage claim = _auctions[_claimToBidOn];
        
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
            
            uint256 userBalance = payable(msg.sender).balance;
        
            if(userBalance < _bidAmount){
                weth.safeApprove(address(this), _bidAmount);
            }

            /*
            (bool done) = IERC20(_tokenAddress).approve(
                address(this), _bidAmount
            );
            require(done);
            */
 /*
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
*/
}