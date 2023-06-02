// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FairWheel, AccessPool} from "../FairWheel.sol";
import {SimpleHelper} from './SimpleHelper.sol';
import {Status, Tag, Item, Auction} from '../DataTypes.sol';
import {PoolStorage} from '../PoolStorage.sol';
import "./mocks/MockVRFCoordinatorV2.sol";
import "./mocks/LinkToken.sol";
import "./mocks/MockNFT.sol";
import {WETH} from "@solmate/tokens/WETH.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import "./utils/Cheats.sol";
import {HelperEvents} from "./HelperEvents.sol";
import "forge-std/Test.sol";

contract FairWheelTest is Test, HelperEvents, PoolStorage {
    using SafeTransferLib for WETH;
    using SafeTransferLib for address;
    //using ERC721 for MockNFT;
   

    LinkToken public linkToken;
    MockNFT public nft;
    WETH internal weth; 
    MockVRFCoordinatorV2 public vrfCoordinator;
    SimpleHelper public randomGenerator;
    FairWheel public fairwheel;
    AccessPool public accessPool;
    Cheats internal constant cheats = Cheats(HEVM_ADDRESS);

    address public admin;
    uint256 public staticTime;

    uint96 constant FUND_AMOUNT = 1 * 10**18;
    uint256 constant NFT_SUPPLY = 10000;
    uint96 constant PRICE_LIMIT = 1e16; 
    uint256[10] PRICE_TAG = [1e20, 75e18, 5e19, 35e18, 2e19, 1e19, 5e18, 1e18, 5e17, 1e16];
    uint256[10] ITEM_AMOUNT = [9e15, 4e17, 2e18, 84e17, 15e18, 24e18, 35e18, 64e18, 754e17, 11e19];
  //  uint256[10] priceTags = [100, 75, 50, 35, 20, 10, 5, 1, 0.5, 0.01];

    uint256 totalNumber;

    // Initialized as blank, fine for testing
    uint64 subId;
    bytes32 keyHash; // gasLane
    address Bob = address(0x73A1);
    address Alice = address(0x14);
    address Tess = address(0x192);

    uint32 defaultAuctionBidPeriod;

    uint256[] fakes; // = new uint256[](10);

    event ReturnedRandomness(uint256 randomWord);

    function setUp() public {
        staticTime = block.timestamp;
        linkToken = new LinkToken();
        weth = new WETH();
        nft = new MockNFT("bafkreiba3o2d3nhwxnjxnpyxrpbqbspuxykpcprrit5rdjxedfiq3gqkkm");
        vrfCoordinator = new MockVRFCoordinatorV2();
        subId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(subId, FUND_AMOUNT);
        fairwheel = new FairWheel(
            WETH(weth),
            subId
            //address(vrfCoordinator),
            
            //keyHash
        );
        randomGenerator = new SimpleHelper(
            subId,
            address(vrfCoordinator),
            address(linkToken),
            keyHash
        );
        vrfCoordinator.addConsumer(subId, address(randomGenerator));
        accessPool = new AccessPool();

        admin = msg.sender;
        defaultAuctionBidPeriod = 86400;
        cheats.warp(staticTime);
    }

/*
    function testAccess() public {
        bytes memory txd = abi.encodeWithSignature("setPriceLimit(uint64)", 20);
        (, bytes memory sad ) = accessPool.see(payable(fairwheel));
        assertEq(sad, txd);
       /* uint64 fad = accessPool.see(payable(fairwheel));
        assertEq(fad, 20);
    }*/

    function CanDepositNFT() public {
        //Not using yet because of float points
        /* for(uint256 i; i < priceTags.length;){
            fairwheel.setPriceTag(i, priceTags[i]);
            assertTrue(fairwheel._priceTags([i]) == priceTags[i]);
            unchecked{i++;}
        } */

        setPriceTag();
        
        uint256 randAmount = 5e18;
        
        //generateRandomObject(msg.sender, 0, ITEM_AMOUNT);

        uint256 randID = 0;
        
        //generateObject(msg.sender, NFT_SUPPLY, fakes);
        
       // assertGt(uint128(randAmount), PRICE_LIMIT);

        uint256 itemId = _itemId;

       // nft.safeTransferFrom(
        //    msg.sender, address(Bob), randID
        //);
        
       // assertTrue(!_deposited[address(nft)]);
        vm.startPrank(Bob);
        nft = new MockNFT("ajdjlfjfjjdld43nckss");

        fairwheel.depositNFT(address(nft), randID, uint128(randAmount));
        
        vm.stopPrank();
        
        uint8 itemLabel = addLabel(randAmount);
        //uint256 newItemId = fairwheel._itemId();
        address nFtowner = nft.ownerOf(randID);

        assertEq(address(fairwheel), nFtowner);
        assertEq(_items[itemId].tokenId, randID);
        assertEq(_items[itemId].askPrice, randAmount);
        //Don't know if it will work
        assertEq(uint8(_items[itemId].label), itemLabel);
        assertTrue(itemId != _itemId);

        vm.expectEmit(true, true, false, true, address(msg.sender));
        emit NFTDeposited( 
            randID,
            randAmount,
            0, 
            _items[itemId].label,
            Status.OFF_LIST,
            payable(msg.sender),
            payable(0),
            payable(0),
            address(nft)
        );
    }

    function testCannotDepositNFTWithEmptyAddress() public {
        //Not using yet because of float points
        /* for(uint256 i; i < priceTags.length;){
            fairwheel.setPriceTag(i, priceTags[i]);
            assertTrue(fairwheel._priceTags([i]) == priceTags[i]);
            unchecked{i++;}
        } */

        setPriceTag();
        
        uint256 randAmount = generateRandomObject(msg.sender, 0, ITEM_AMOUNT);
        uint256 randID = generateObject(msg.sender, NFT_SUPPLY, fakes);
        
        assertGt(uint128(randAmount), PRICE_LIMIT);

        uint256 itemId = _itemId;

        vm.prank(Bob);
        
        //assertTrue(_deposited[address(nft)]);
        fairwheel.depositNFT(address(0), randID, uint128(randAmount));
        vm.expectRevert();
    }

    function testCannotDepositWithInvalidInputs() public {
        //Not using yet because of float points
        /* for(uint256 i; i < priceTags.length;){
            fairwheel.setPriceTag(i, priceTags[i]);
            assertTrue(fairwheel._priceTags([i]) == priceTags[i]);
            unchecked{i++;}
        } */

        setPriceTag();
        
        uint256 randAmount = generateRandomObject(msg.sender, 0, ITEM_AMOUNT);

        uint256 randID = generateObject(msg.sender, NFT_SUPPLY, fakes);

        assertLt(uint128(randAmount), PRICE_LIMIT);

        uint256 itemId = _itemId;

        vm.prank(Alice);

        fairwheel.depositNFT(address(nft), randID, uint128(randAmount));

        vm.expectRevert();
    }

    function addLabel(uint256 item) internal returns(uint8){

        if(item < PRICE_TAG[0]){
            return 0;
        }
        if(item >= PRICE_TAG[1]){
            return 1; 
        } 
        if(item >= PRICE_TAG[2]){
            return 2;
        } 
        if(item >= PRICE_TAG[3]){
            return 3;
        } 
        if(item >= PRICE_TAG[4]){
            return 4;
        } 
        if(item >= PRICE_TAG[5]){
            return 5;
        } 
        if(item >= PRICE_TAG[6]){
            return 6;
        } 
        if(item >= PRICE_TAG[7]){
            return 7;
        } 
        if(item >= PRICE_TAG[8]){
            return 8;
        } 
        if(item >= PRICE_TAG[9]){
            return 9;
        }

    }

    function setPriceTag(
        //uint8 _priceTagId, 
        //uint256 _value
    ) public {
        //require(_value != 0, "INVALID_INPUT");
        for(uint256 i; i < _priceTags.length;){
            _priceTags[i] = PRICE_TAG[i];
            assertEq(_priceTags[i], PRICE_TAG[i]);
            unchecked{i++;}
        }
    //_priceTags[_priceTagId] = _value * 1e18;
      //  return _priceTags[_priceTagId];
    }

    function getTagDetails() internal returns(Tag) {
        uint256 r = generateObject(msg.sender, 10, fakes);

        if(uint8(Tag.TIER_ONE) == uint8(r))
        return Tag.TIER_ONE;
        if(uint8(Tag.TIER_TWO) == uint8(r))
        return Tag.TIER_TWO;
        if(uint8(Tag.TIER_THREE) == uint8(r))
        return Tag.TIER_THREE;
        if(uint8(Tag.TIER_FOUR) == uint8(r))
        return Tag.TIER_FOUR;
        if(uint8(Tag.TIER_FIVE) == uint8(r))
        return Tag.TIER_FIVE;
        if(uint8(Tag.TIER_SIX) == uint8(r))
        return Tag.TIER_SIX;
        if(uint8(Tag.TIER_SEVEN) == uint8(r))
        return Tag.TIER_SEVEN;
        if(uint8(Tag.TIER_EIGHT) == uint8(r))
        return Tag.TIER_EIGHT;
        if(uint8(Tag.TIER_NINE) == uint8(r))
        return Tag.TIER_NINE;
        if(uint8(Tag.BOTTOM_T) == uint8(r))
        return Tag.BOTTOM_T;
    }

    function testCanStartAuction() public {
        
        Tag label = getTagDetails();

       // uint256 r = generateObject(msg.sender, 10, fakes);

        uint256 claim = _claimsOnAuction;
         
        vm.prank(Alice);

        /*

        if(uint8(Tag.TIER_ONE) == uint8(r))
        startNewAuction(Tag.TIER_ONE);
        if(uint8(Tag.TIER_TWO) == uint8(r))
        startNewAuction(Tag.TIER_TWO);
        if(uint8(Tag.TIER_THREE) == uint8(r))
        startNewAuction(Tag.TIER_THREE);
        if(uint8(Tag.TIER_FOUR) == uint8(r))
        startNewAuction(Tag.TIER_FOUR);
        if(uint8(Tag.TIER_FIVE) == uint8(r))
        startNewAuction(Tag.TIER_FIVE);
        if(uint8(Tag.TIER_SIX) == uint8(r))
        startNewAuction(Tag.TIER_SIX);
        if(uint8(Tag.TIER_SEVEN) == uint8(r))
        startNewAuction(Tag.TIER_SEVEN);
        if(uint8(Tag.TIER_EIGHT) == uint8(r))
        startNewAuction(Tag.TIER_EIGHT);
        if(uint8(Tag.TIER_NINE) == uint8(r))
        startNewAuction(Tag.TIER_NINE);
        if(uint8(Tag.BOTTOM_T) == uint8(r))
        startNewAuction(Tag.BOTTOM_T); */

     //   Tag label = uint8(r);

        startNewAuction(label);

        assertTrue(_claimsOnAuction != claim);
    }

    function startNewAuction(Tag _label) public {

        uint256 i; uint256 j;

        //declared an "offList" array to store the Ids of items 
        //with the "_label" and "OFF_LIST" tags
        uint256[] memory offList = new uint[](j);

        uint256 itemCount = _itemId;

        while(i < itemCount){
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

        uint256 floorPrice = fairwheel.getFloorPrice(_label);

        uint256 userBalance = payable(msg.sender).balance;
        
        if(userBalance < floorPrice){
            weth.safeApprove(address(fairwheel), floorPrice);
        }
        
       /* (bool approved) = address(0).approve(
            address(this), floorPrice
        );
        require(approved);*/
        
        uint256 rand = generateObject(
            msg.sender, 0, offList
        ); 

        _items[rand].status = Status.ON_LIST;

        uint256 claim = _claimsOnAuction;

        _auctions[claim] = Auction({
            highestBid: floorPrice,
            label: _label,
            auctionTimeLeft: defaultAuctionBidPeriod,
            highestBidder: payable(msg.sender)
        });   
        
        _onAuction[claim] = true; 

        _claimsOnAuction++;

        assertTrue(_onAuction[claim] == true);
        assertTrue(_claimsOnAuction != claim);
        assertTrue(_items[rand].status == Status.ON_LIST);
        assertTrue(floorPrice != 0);

        vm.expectEmit(false, false, false, true, address(msg.sender));

        emit NewAuctionStarted(
            _label, 
            claim, 
            _auctions[claim].auctionTimeLeft, 
            _auctions[claim].highestBid, 
            msg.sender
        ); 
    }

    function testCanBidForClaims() public {
        Tag label = getTagDetails();
        
        uint256 claim = generateObject(msg.sender, _claimsOnAuction, fakes);

        uint256 randomAmount = generateRandomObject(msg.sender, 0, ITEM_AMOUNT);
        
        fairwheel.setMinBidIncreasePercentage(10);
      //  uint64 increasePercentage = fairwheel._minBidIncreasePercentage();
        
        uint256 etherAmount = 500 ether;

        vm.deal(Tess, etherAmount);

        fairwheel.bidForClaims(uint8(label), claim, randomAmount);

        uint32 timeLeft = fairwheel.getClaimBidTimeLeft(claim);

        Auction storage claiM = _auctions[claim];
        assertEq(claiM.highestBid, randomAmount);
        assertEq(claiM.highestBidder, msg.sender);

        vm.expectEmit(false, false, false, true, address(msg.sender));
        
        emit NewBidMade(
            uint8(label), 
            claiM, 
            timeLeft, 
            randomAmount, 
            msg.sender
        );
    } 

    function testCanHaveMultipleBidsForAClaim() public {
        Tag label = getTagDetails();
        
        uint256 claim = generateObject(msg.sender, _claimsOnAuction, fakes);

        uint256 randomAmount = generateRandomObject(msg.sender, 0, ITEM_AMOUNT);
        
        fairwheel.setMinBidIncreasePercentage(10);

      //            FIRST CALL
        
        uint256 etherAmount = 500 ether;

        vm.deal(Tess, etherAmount);
        vm.prank(Tess);

        fairwheel.bidForClaims(uint8(label), claim, randomAmount);

        uint32 timeLeft = fairwheel.getClaimBidTimeLeft(claim);

        Auction storage claiM = _auctions[claim];

        assertEq(claiM.highestBid, randomAmount);
        assertEq(claiM.highestBidder, Tess);

        vm.expectEmit(false, false, false, true, address(Tess));
        
        emit NewBidMade(
            uint8(label), 
            claiM, 
            timeLeft, 
            randomAmount, 
            Tess
        );


        //      SECOND CALL

        vm.warp(36400);
        vm.deal(Bob, etherAmount);
        vm.startPrank(Bob);

        fairwheel.bidForClaims(uint8(label), claim, randomAmount + 5);

        vm.expectRevert();
        
        assertEq(claiM.highestBid, randomAmount);
        assertEq(claiM.highestBidder, Tess);


        //      THIRD CALL (Bob's second call)
        
        vm.warp(74850);

        uint256 newAmount = (randomAmount / 10) + randomAmount;

        fairwheel.bidForClaims(uint8(label), claim, newAmount);
        
        timeLeft = fairwheel.getClaimBidTimeLeft(claim);

        vm.stopPrank();

        vm.expectEmit(false, false, false, true, address(Bob));
        
        emit NewBidMade(
            uint8(label), 
            claiM, 
            timeLeft, 
            newAmount, 
            Bob
        );

        assertEq(claiM.highestBid, newAmount);
        assertEq(claiM.highestBidder, Bob);


        //      FOURTH CALL (Alice's call)

        newAmount = newAmount ** 3;  
        etherAmount = 900 ether;
        vm.deal(Alice, etherAmount);
        vm.prank(Alice);
        vm.warp(86399);

        fairwheel.bidForClaims(uint8(label), claim, newAmount);

        timeLeft = fairwheel.getClaimBidTimeLeft(claim);
        vm.expectEmit(false, false, false, true, address(Alice));
        
        emit NewBidMade(
            uint8(label), 
            claiM, 
            timeLeft, 
            newAmount, 
            Alice
        );
        
        assertEq(claiM.highestBid, newAmount);
        assertEq(claiM.highestBidder, Alice);


        //      FINAL CALL (Tess's last call)

        newAmount = newAmount ** 2;  
        //etherAmount = 900 ether;
        vm.deal(Tess, etherAmount);
        vm.prank(Tess);

        vm.warp(86400);

        fairwheel.bidForClaims(uint8(label), claim, newAmount);

        vm.expectRevert();

        assertTrue(claiM.highestBid != newAmount);
        assertEq(claiM.highestBidder, Alice);
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

    function testCanAssignClaimingRights() public {
        Tag _label = getTagDetails();

        uint256 index;
        while(index < _claimsOnAuction){
            if(_auctions[index].label == _label){
                if(fairwheel.getClaimBidTimeLeft(index) == 0){
                    uint256 randomId = _deliverItem(_label);
                    Item storage item = _items[randomId];
                    Auction memory claim = _auctions[index];

                    item.rightToClaim = claim.highestBidder;
                    item.soldPrice = claim.highestBid;
                    item.status = Status.OUT;

                    assertEq(item.rightToClaim, claim.highestBidder);
                    assertEq(item.soldPrice, claim.highestBid);
                    assertTrue(item.status == Status.OUT);

                }
            }

            unchecked {
                index++;  
            }
        }

        cheats.expectEmit(false, false, false, true);
        emit ClaimingRightsAssigned(
            uint8(_label)
        );
    }

    function _deliverItem(Tag _label) internal returns(uint256) {
       // vm.assume(_label < 10);
        uint256 i; uint256 j; 
        
        uint256[] memory itemsList = new uint[](j);

        uint256 itemNum = _itemId;

        while(i < itemNum){
            if(_items[i].label == _label){
                if(_items[i].status == Status.ON_LIST){
                    itemsList[j] = i;
                    j++;
                }
            }

            unchecked {
                i++;  
            }
        }

        uint256 rand = generateObject(
            msg.sender, 0, itemsList
        );

        // a placeholder to remove objects if random generator inheritance doesn't work during tests
        //remove(objects[objectId]);

        return rand;
    } 


    function testCanClaimNft(
      //  uint8 _label, 
      //  uint256 _claim, 
      //  address _nftRecipient
    ) external {
        /*
        vm.assume(_label < 10);
        vm.assume(_claim <= _auctions);
        vm.assume(_nftRecipient != 0);*/

        Tag _label = getTagDetails();
        
        uint256 _claim = generateObject(msg.sender, _claimsOnAuction, fakes);

        /*uint256 randomAmount = generateRandomObject(msg.sender, 0, ITEM_AMOUNT);*/

        Auction memory claim = _auctions[_claim];
        require(msg.sender == claim.highestBidder, "WRONG_AUCTION_ID");
        testCanAssignClaimingRights();

        uint256 itemNum = _itemId;

        uint256 i;
        while(i < itemNum){
            Item memory collect = _items[i];

            if(_items[i].label == _label && 
            collect.status == Status.OUT){
                
                if(collect.rightToClaim == claim.highestBidder && 
                collect.soldPrice == claim.highestBid){

                    uint256 etherAmount = 1000 ether;
                    vm.deal(Alice, etherAmount);
                    vm.startPrank(Alice);

                    uint256 userBalance = payable(msg.sender).balance;
        
                    if(userBalance < collect.soldPrice){
                        weth.safeApprove(address(fairwheel), collect.soldPrice);
                    }
                    
                    /*
                    (bool checked) = address(0).approve(
                        address(fairwheel), collect.soldPrice
                    );
                    assertTrue(checked); */

                    //uint256 etherAmount = 500 ether;

                  //  vm.deal(msg.sender, etherAmount);

                    fairwheel.setProtocolFeePercentage(10);
                    
                    _purchaseItem(i, msg.sender);
                    _resetAll(i, _claim);

                    vm.stopPrank();
                    address owner = nft.ownerOf(collect.tokenId);

                    assertEq(Alice, owner);
                    
           //         uint256 saveI = i;
                    break;
                }
            }

            unchecked {
                i++;  
            }
        }

        cheats.expectEmit(false, false, false, true);
        emit NftWithdrawn(
            _items[i], 
            uint8(_label), 
            _claim
        );

        // assertEq(i, saveI);
    }

    function _purchaseItem(
        uint256 _item, 
        address _nftRecipient
    ) internal {
        Item storage item = _items[_item];

        item.nftRecipient = _getNftRecipient(_item, _nftRecipient);

        _payFeeAndSeller(item);

        ///@dev Uses safeTransferFrom to check if "item.nftRecipient" 
        ///     can receive Nft before execution
        ERC721(item.nftContract).safeTransferFrom(
            address(fairwheel),
            item.nftRecipient,
            item.tokenId
        );

        /* solmate's transfer function
        ERC721(item.nftContract).safeTransferFrom(
            address(this),
            item.nftRecipient,
            item.tokenId
        ); */

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

    function _payFeeAndSeller(Item memory _item) internal {
        
        uint256 fee = _getPortionOfBid(_item.soldPrice);

        _payout(_item, (_item.soldPrice - fee), fee);
    }


    /// @dev Originally, it should be paid to the BeeCard - token wrapper NFT(ERC1155) 
    ///      But it hasn't been implemented yet.
    function _payout(
        Item memory _item, 
        uint256 _amount,
        uint256 _fee
    ) internal {
        
        //payable(msg.sender).approve(address(this), _tokenAddress) _item.BeeCardId);
        //payable(msg.sender).safeTransferETH(_fee);

        
        //Pays the fee to the contract
        (bool received, ) = payable(address(fairwheel)).call{
            value: _fee,
            gas: 20000
        }("");

 //       require(received);
        if(!received){  //_tokenAddress.safeTransfer(address(this), _fee);
            (bool done) = weth.transfer(  //use transfer except approve function don't work
                address(fairwheel), _fee);
            require(done);
        }

        // An ETH call - attempt to send the funds to the recipient
        (bool success, ) = payable(_item.seller).call{
            value: _amount,
            gas: 20000
        }("");
        
        //if it fails, send to this contract 
        if (!success) {
            (bool sent, ) = payable(address(fairwheel)).call{
                value: _amount,
                gas: 20000
            }("");
            
            //if it fails, try an erc20 token(WETH) || send it to this contract
            if (!sent) { 
                //_tokenAddress.safeTransferFrom(msg.sender, _item.seller, _amount) || _tokenAddress.safeTransfer(address(this), _amount);
                (bool paid) = weth.transferFrom(
                    msg.sender, _item.seller, _amount) ||
                        weth.transfer(address(fairwheel), _amount
                    );
                        
                require(paid);
            }

            //    burn(_item.BeeCardId);
            //Update their credit on the contract so they can pull it later
            
            _failedTransferCredits[_item.seller] = _failedTransferCredits[_item.seller] + _amount;
        }
    }

    function _resetAll(
        uint256 _itemIndex, 
        uint256 _claimIndex
    ) internal {
       _removeItem(_itemIndex);
       _removeClaim(_claimIndex);
    }
    
    
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
        while(i < _claimsOnAuction){
           _auctions[i] = _auctions[i + 1]; 
            unchecked {
                i++;  
            }
           delete _auctions[i];
          _claimsOnAuction = _claimsOnAuction - 1; 
        }   
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
        uint256[10] memory _itemList
    ) internal returns(uint256){

        totalNumber = _number;
        
       /* uint256 i;
        while(i < _itemList){
            if(i != 0)
            unchecked{++i;}
        }*/

        uint256[10] memory _objectsId;

        for(uint256 i; i < _itemList.length; i++){
            if(i != 0)
            _objectsId = _itemList;
        }
        

        randomGenerator.requestRandomness(_searcher);

        uint256 requestId = randomGenerator.s_requestId();

        // When testing locally you MUST call fulfillRandomness youself to get the
        // randomness to the consumer contract, since there isn't a chainlink node on your local network
        vrfCoordinator.fulfillRandomWords(requestId, address(randomGenerator));
        uint256 objectValue = (randomGenerator.s_randomWords(0) % _objectsId.length) + 1;
        
        //randomGenerator.s_results([s_callers[requestId]]) = objectValue;
        
      //  testCanGetRandomResponse(requestId, objectValue);

        uint256 rand = randomGenerator.checkStatus(_searcher);

        //randomGenerator._removeObjects();
        bool yes = randomGenerator.deleteResult(_searcher);
        assertTrue(yes);
        
        return rand;
    }

    function generateObject(
        address _searcher, 
        uint256 _number,
        uint256[] memory _itemList
    ) internal returns(uint256){

        totalNumber = _number;
        
       /* uint256 i;
        while(i < _itemList){
            if(i != 0)
            unchecked{++i;}
        }*/
        
        bool done = randomGenerator.addObjects(_itemList);
        assertTrue(done); 
        // = _itemList.length;
        

        randomGenerator.requestRandomness(_searcher); 

        uint256 requestId = randomGenerator.s_requestId();

        uint256 word = getWords(requestId);

        vm.deal(address(randomGenerator), 1000000 ether);
        vm.prank(address(vrfCoordinator));

        // When testing locally you MUST call fulfillRandomness youself to get the
        // randomness to the consumer contract, since there isn't a chainlink node on your local network
        (bool success,) = address(vrfCoordinator).call{gas: 10000000000}(abi.encodeWithSignature("fulfillRandomWords(uint256,address)", requestId, address(randomGenerator)));
        assertTrue(success);

        assertEq(randomGenerator.s_randomWords(0), word);

        uint256 randomWord = randomGenerator.s_randomWords(0);

        //// problem here
        uint256 objectValue = (randomWord % getObjectsNum()) + 1;

        
        //there's a possibility of this being false for a single variable
        assertEq(randomGenerator.getResults(requestId), objectValue);
        
        
        //canGetRandomResponse(requestId, objectValue);

        uint256 rand = randomGenerator.checkStatus(_searcher);

        randomGenerator._removeObjects();

        bool yes = randomGenerator.deleteResult(_searcher);
        assertTrue(yes);
        
        return rand;
    }

    function getObjectsNum() private view returns(uint256) {
        uint256 objects = randomGenerator.getObjectsNum();
        if(objects == 0){
           return totalNumber;
        }
        return objects;
    } 

    function CanGetRandomResponse(uint256 _requestId, uint256 _objectValue) public {
        //uint256 randAmount = generateRandomObject(msg.sender, 0, ITEM_AMOUNT);

        randomGenerator.requestRandomness(msg.sender);
        uint256 requestId = randomGenerator.s_requestId();

        uint256 word = getWords(_requestId);

        // When testing locally you MUST call fulfillRandomness youself to get the
        // randomness to the consumer contract, since there isn't a chainlink node on your local network
       // vrfCoordinator.fulfillRandomWords(requestId, address(randomGenerator));
        //uint256 objectValue = (randomGenerator.s_randomWords(0) % randomGenerator.getObjectsNum()) + 1;
        
       // randomGenerator.s_results([s_callers[requestId]]) = objectValue;
        
        //there's a possibility of this being false for a single variable
        assertEq(randomGenerator.getResults(_requestId), _objectValue);
        assertEq(randomGenerator.s_randomWords(0), word);
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
        vrfCoordinator.fulfillRandomWords(requestId, address(randomGenerator));
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