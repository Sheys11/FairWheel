// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../FairWheel.sol";
import {RandomGenerator} from '../RandomGenerator.sol';
import "./mocks/MockVRFCoordinatorV2.sol";
import "./mocks/LinkToken.sol";
import "./mocks/MockNFT.sol";
import "./utils/Cheats.sol";
import "forge-std/Test.sol";

contract VRFConsumerV2Test is Test {
    LinkToken public linkToken;
    MockNFT public nft;
    MockVRFCoordinatorV2 public vrfCoordinator;
    RandomGenerator public randomGenerator;
    FairWheel public fairwheel;
    Cheats internal constant cheats = Cheats(HEVM_ADDRESS);

    address public admin;
    uint256 public staticTime;

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

    uint96 constant FUND_AMOUNT = 1 * 10**18;
    uint256 constant NFT_SUPPLY = 10000;
    uint96 constant PRICE_LIMIT = 1e16; 
    uint256[10] constant PRICE_TAG = {1e20, 75e18, 5e19, 35e18, 2e19, 1e19, 5e18, 1e18, 5e17, 1e16};
    uint256[10] constant ITEM_AMOUNT = {9e15, 4e17, 2e18, 84e17, 15e18, 24e18, 35e18, 64e18, 754e17, 11e19};
    uint256[10] constant priceTags = {100, 75, 50, 35, 20, 10, 5, 1, 0.5, 0.01};

    uint256 totalNumber;

    // Initialized as blank, fine for testing
    uint64 subId;
    bytes32 keyHash; // gasLane

    uint32 defaultAuctionBidPeriod;

    event ReturnedRandomness(uint256[] randomWords);

    function setUp() public {
        staticTime = block.timestamp;
        linkToken = new LinkToken();
        nft = new MockNFT();
        vrfCoordinator = new MockVRFCoordinatorV2();
        subId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(subId, FUND_AMOUNT);
        fairwheel = new FairWheel(
            subId,
            //address(vrfCoordinator),
            address(linkToken),
            //keyHash
        );
        randomGenerator = new RandomGenerator(
            subId,
            address(vrfCoordinator),
            address(linkToken),
            keyHash
        );
        vrfCoordinator.addConsumer(subId, address(randomGenerator));
        

        admin = msg.sender;
        defaultAuctionBidPeriod = 86400;
        cheats.warp(staticTime);
    }

    function testCanDepositNFT() public {
        //Not using yet because of float points
        /* for(uint256 i; i < priceTags.length;){
            fairwheel.setPriceTag(i, priceTags[i]);
            assertTrue(fairwheel._priceTags([i]) == priceTags[i]);
            unchecked{i++;}
        } */

        setPriceTag();
        uint256 randAmount = generateRandomObject(msg.sender, 0, ITEM_AMOUNT);
        uint256 randID = generateRandomObject(msg.sender, NFT_SUPPLY, 0);
        uint256 itemId = fairwheel._itemId();
        fairwheel.depositNFT(address(nft), randID, uint128(randAmount));
        assertTrue(address(nft) != address(0));
        assertTrue(randID != 0);
        assertTrue(uint128(randAmount) >= PRICE_LIMIT);
        assertTrue(!fairwheel.deposited([address(nft)]));

       // IERC721(_nftAddress).transferFrom(
         //   msg.sender, address(this), _tokenId
        //);
        
        uint256 itemLabel = addLabel(randAmount);
        //uint256 newItemId = fairwheel._itemId();

        assertTrue(address(fairwheel) == nft._ownerOf[randID]);
        assertTrue(fairwheel._deposited([address(nft)]) == true);
        assertTrue(fairwheel._items([itemId].tokenId) == randID);
        assertTrue(fairwheel._items([[itemId].askPrice) == randAmount);
        //Don't know if it will work
        assertTrue(fairwheel.uint256(_items([[itemId].label)) == itemLabel);
        assertTrue(itemId != fairwheel._itemId());

        cheats.expectEmit(false, false, false, true);
        emit NFTDeposited(randAmount, randID, itemLabel, itemId);
    }

    function addLabel(uint256 item) internal returns(uint256){
       //uint256 item = _item;
 
        if(item < PRICE_TAG[0]){
            if(item >= PRICE_TAG[1]){
                return 1; 
            } else if(item >= PRICE_TAG[2]){
                return 2;
            } else if(item >= _priceTags[3]){
                return 3;
            } else if(item >= _priceTags[4]){
                return 4;
            } else if(item >= PRICE_TAG[5]){
                return 5;
            } else if(item >= PRICE_TAG[6]){
                return 6;
            } else if(item >= PRICE_TAG[7]){
                return 7;
            } else if(item >= PRICE_TAG[8]){
                return 8;
            } else if(item >= PRICE_TAG[9]){
                return 9;
            }
        }
        return 0;
    }

    function setPriceTag(
        //uint8 _priceTagId, 
        //uint256 _value
    ) public {
        //require(_value != 0, "INVALID_INPUT");
        for(uint256 i; i < fairwheel._priceTags.length();){
            fairwheel._priceTags([i]) = PRICE_TAG[i];
            assertTrue(fairwheel._priceTags([i]) == PRICE_TAG[i]);
            unchecked{i++;}
        }
    //_priceTags[_priceTagId] = _value * 1e18;
      //  return _priceTags[_priceTagId];
    }

    function testCanStartAuction() public {
        Tag label = generateRandomObject(msg.sender, 0, uint256(Tag));
        startNewAuction(label);
        
    }

    function startNewAuction(DataTypes.Tag _label) public {
    
        uint256 i; uint256 j;

        //declared an "offList" array to store the Ids of items 
        //with the "_label" and "OFF_LIST" tags
        uint256[] memory offList = new uint[](j);

        uint256 itemCount = fairwheel._itemId();

        while(i < itemCount){
            fairwheel.Item() memory item = fairwheel._items([i]);
            if(item.label == _label){
                if(item.status == fairwheel.Status.OFF_LIST()){
                    offList[j] = i;
                    j++;
                } 
            }

            unchecked {
                i++;
            }
        }

        uint256 floorPrice = fairwheel._getFloorPrice(_label);
        
        (bool approved) = address(linkToken).approve(
            address(this), floorPrice
        );
        require(approved);
        
        uint256 rand = generateRandomObject(
            msg.sender, 0, offList
        ); 

        fairwheel._items([rand].status) = fairwheel.Status.ON_LIST();

        uint256 claim = fairwheel._claimsOnAuction();

        fairwheel._auctions([claim]) = fairwheel.Auction({
            highestBid: floorPrice,
            label: _label,
            auctionTimeLeft: defaultAuctionBidPeriod,
            highestBidder: payable(msg.sender)
        });   
        
        fairwheel._onAuction([claim]) = true; 

        fairwheel._claimsOnAuction(++);

        assertTrue(fairwheel._onAuction([claim]) == true);
        assertTrue(fairwheel._claimsOnAuction() != claim);
        assertTrue(fairwheel._items([rand].status) == fairwheel.Status.ON_LIST());
        assertTrue(floorPrice != 0);

        cheats.expectEmit(false, false, false, true);

        emit NewAuctionStarted(
            _label, 
            claim, 
            fairwheel._auctions([claim].auctionTimeLeft), 
            fairwheel._auctions([claim].highestBid), 
            msg.sender
        ); 
    }

    function testCanBidForClaims() public {
        Tag label = generateRandomObject(msg.sender, 0, uint256(Tag));
        uint256 claim = generateRandomObject(msg.sender, fairwheel.claimsOnAuction(), 0);
        uint256 randomAmount = generateRandomObject(msg.sender, 0, ITEM_AMOUNT);
        fairwheel.setMinBidIncreasePercentage(10);
      //  uint64 increasePercentage = fairwheel._minBidIncreasePercentage();
        
        fairwheel.bidForCLaims(label, claim, randomAmount);
        uint32 timeLeft = fairwheel._timeLeft(claim);
        DataTypes.Auction() storage claiM = fairwheel._auctions([claim]);
        assertTrue(claiM.highestBid == randomAmount);
        assertTrue(claiM.highestBidder == msg.sender);
        cheats.expectEmit(false, false, false, true);
        
            emit NewBidMade(
                label, 
                claim, 
                timeLeft, 
                randomAmount, 
                msg.sender
            );
    } 

/*
    function bidForClaims(
        uint8 _label, 
        uint256 _claimToBidOn, 
        uint256 _bidAmount
    ) public {
        assertTrue(_bidAmount != 0, "INVALID_INPUT");
        assertTrue(fairwheel._onAuction([_claimToBidOn]) == true, "ITEM_NOT_ON_AUCTION");

        DataTypes.Auction() storage claim = fairwheel._auctions([_claimToBidOn]);
        
        assertTrue(uint8(claim.label) == _label, "WRONG_POOL");
        
        ///@dev Checks if auction is still on - Auction time is 24 hrs
        uint32 timeLeft = fairwheel._timeLeft(_claimToBidOn);

        fairwheel.setMinBidIncreasePercentage(10);

        uint increasePercentage = fairwheel._minBidIncreasePercentage();

        if(timeLeft != 0){
            //Bid amount must meet the minimum bid increase 
            // percentage of current claim
            assertTrue((_bidAmount - claim.highestBid) >= (
                claim.highestBid * increasePercentage
                ); //, "YOUR_BID_IS < _minBidIncreasePercentage_OF_CURRENT_BID"
            //);
            
            (bool done) = address(linkToken).approve(
                address(fairwheel), _bidAmount
            );
            assertTrue(done);

            claim.highestBid = _bidAmount;
            claim.highestBidder = msg.sender;

            cheats.expectEmit(false, false, false, true);
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

    function testCanAssignClaimingRights(uint8 _label) public {
        uint256 index;
        while(index < fairwheel._claimsOnAuction()){
            if(uint8(fairwheel._auctions([index].label)) == _label){
                if(fairwheel._timeLeft(index) == 0){
                    uint256 randomId = _deliverItem(_label);
                    DataTypes.Item() storage item = fairwheel._items([randomId]);
                    DataTypes.Auction() memory claim = fairwheel._auctions([index]);

                    item.rightToClaim = claim.highestBidder;
                    item.soldPrice = claim.highestBid;
                    item.status = DataTypes.Status.OUT;

                    assertTrue(item.rightToclaim == claim.highestBidder);
                    assertTrue(item.soldPrice == claim.highestBid);
                    assertTrue(item.status == DataTypes.Status(.OUT));

                }
            }

            unchecked {
                index++;  
            }
        }

        cheats.expectEmit(false, false, false, true);
        emit ClaimingRightsAssigned(
            _label
        );
    }

    function _deliverItem(uint8 _label) internal returns(uint256) {
        uint256 i; uint256 j; 
        
        uint256[] memory itemsList = new uint[](j);

        uint256 itemNum = fairwheel._itemId();

        while(i < itemNum){
            if(uint8(fairwheel._items([i].label)) == _label){
                if(fairwheel._items([i].status) == DataTypes.Status(.ON_LIST)){
                    itemsList[j] = i;
                    j++;
                }
            }

            unchecked {
                i++;  
            }
        }

        uint256 rand = generateRandomObject(
            msg.sender, 0, itemsList
        );

        // a placeholder to remove objects if random generator inheritance doesn't work during tests
        //remove(objects[objectId]);

        return rand;
    } 


    function testCanClaimNft(
        uint8 _label, 
        uint256 _claim, 
        address _nftRecipient
    ) external {
        DataTypes.Auction() memory claim = fairwheel._auctions([_claim];
        require(msg.sender == claim.highestBidder, "WRONG_AUCTION_ID");
        testCanAssignClaimingRights(_label);

        uint256 itemNum = fairwheel._itemId();

        uint256 i;
        while(i < itemNum){
            DataTypes.Item() storage item = fairwheel._items([i]);

            if(uint8(fairwheel._items([i].label)) == _label && 
            item.status == DataTypes.Status(.OUT)){
                
                if(item.rightToClaim == claim.highestBidder && 
                item.soldPrice == claim.highestBid){
                    
                    (bool checked) = address(linkToken).approve(
                        address(fairwheel), item.soldPrice
                    );
                    assertTrue(checked);

                    fairwheel.setProtocolFeePercentage(10);
                    
                    fairwheel._purchaseItem(i, _nftRecipient);
                    fairwheel._resetAll(i, _claim);
                    
                    break;
                }
            }

            unchecked {
                i++;  
            }
        }

        cheats.expectEmit(false, false, false, true);
        emit NftWithdrawn(
            item, 
            _label, 
            _claim
        );
    }

   // function testRequiresinDepositNFT(_)

    function testCanRequestRandomness() public {
        uint256 startingRequestId = randomGenerator.s_requestId();
        randomGenerator.requestRandomness(msg.sender);
        assertTrue(randomGenerator.s_requestId() != startingRequestId);
    }

    function generateRandomObject(
        address _searcher, 
        uint256 _number,
        uint256[] memory _itemList
    ) internal returns(uint256){

        totalNumber = _number;
        
        randomGenerator._objectsId() = _itemList;

        randomGenerator.requestRandomness(_searcher);

        uint256 requestId = randomGenerator.s_requestId();

        // When testing locally you MUST call fulfillRandomness youself to get the
        // randomness to the consumer contract, since there isn't a chainlink node on your local network
        vrfCoordinator.fulfillRandomWords(requestId, address(randomGenerator));
        uint256 objectValue = (randomGenerator.s_randomWords(0) % getObjectsNum()) + 1;
        
        //randomGenerator.s_results([s_callers[requestId]]) = objectValue;
        
        testCanGetRandomResponse(requestId, objectValue);

        uint256 rand = randomGenerator.checkStatus(_searcher);

        randomGenerator._removeObjects();
        randomGenerator.s_results([_searcher]) = 0;
        
        return rand;
    }

    function getObjectsNum() private view returns(uint256) {
        uint256 objects = randomGenerator._objectsId.length();
        if(objects == 0){
           return totalNumber;
        }
        return objects;
    } 

    function testCanGetRandomResponse(uint256 _requestId, uint256 _objectValue) public {
        //uint256 randAmount = generateRandomObject(msg.sender, 0, ITEM_AMOUNT);

        //randomGenerator.requestRandomness(msg.sender);
        //uint256 requestId = randomGenerator.s_requestId();

        uint256 word = getWords(_requestId);

        // When testing locally you MUST call fulfillRandomness youself to get the
        // randomness to the consumer contract, since there isn't a chainlink node on your local network
       // vrfCoordinator.fulfillRandomWords(requestId, address(randomGenerator));
        //uint256 objectValue = (randomGenerator.s_randomWords(0) % randomGenerator.getObjectsNum()) + 1;
        
       // randomGenerator.s_results([s_callers[requestId]]) = objectValue;
        
        //there's a possibility of this being false for a single variable
        assertTrue(randomGenerator.s_results([s_callers[_requestId]]) == _objectValue);
        assertTrue(randomGenerator.s_randomWords(0) == word);
        //assertTrue(vrfConsumer.s_randomWords(1) == words[1]);
    }

    function testEmitsEventOnFulfillment() public {
        randomGenerator.requestRandomness(msg.sender);
        uint256 requestId = randomGenerator.s_requestId();
        uint256 word = getWords(requestId);

        cheats.expectEmit(false, false, false, true);
        emit ReturnedRandomness(word);
        // When testing locally you MUST call fulfillRandomness youself to get the
         // randomness to the consumer contract, since there isn't a chainlink node on your local network
        vrfCoordinator.fulfillRandomWords(requestId, address(vrfConsumer));
    }

    function getWords(uint256 requestId)
        public
        view
        returns (uint256)
    {
        //uint256[] memory words = new uint256[](randomGenerator.numWords());
        //for (uint256 i = 0; i < randomGenerator.numWords(); i++) {
          uint256 word = uint256(keccak256(abi.encode(requestId)));
        //}
        return word;
    }
}