//SPDX-License-Identifier: MIT
pragma solidity^0.8.17;

//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
///@dev using solmate for gas optimisation. Previous use of openzeppelin is present for better understanding
import "@solmate/tokens/ERC721.sol";
import "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {WETH} from "@solmate/tokens/WETH.sol";
import {RandomGenerator} from "./RandomGenerator.sol";
import {Status, Tag, Item, Auction} from './DataTypes.sol';
import {PoolStorage} from './PoolStorage.sol';

error BidFailed(string);

/**
 * @title FairWheel Marketplace
 * @dev The main nft marketplace contract where all trades logic are present.
 * This contract should NOT define storage as it is managed by PoolStorage.
 * This contract isn't complete/optimized and should have other useful features like being upgradeable
 */
contract FairWheel is PoolStorage, RandomGenerator {
    using SafeTransferLib for WETH;
    using SafeTransferLib for address;

    WETH internal immutable weth; 

 //   ERC20 internal immutable weth;


    //IERC20 public _tokenAddress;

    address public _admin;


    modifier ifAdmin() {
        if (msg.sender != _admin) revert();
        _;
    }

/*
=====================================================================================================
============================================= EVENTS ================================================
=====================================================================================================
*/
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


    /**
     * @dev The constructor initialises the VRF subscription id from chainlink and an erc20 token address that
     *      that can be accepted aside ether - posssibly WETH. 
     *      Also assigns admin's role to deployer and sets "_defaultAuctionBidPeriod" as 24 hrs.
     * @param _subscriptionId Chainlink VRF's subscriptionId
     */
    constructor(WETH _weth, uint64 _subscriptionId) RandomGenerator(_subscriptionId) {
      //_tokenAddress = tokenAddress_;
      weth = _weth;   //WETH(_weth);
      _admin = address(this);
      _defaultAuctionBidPeriod = 86400; // 1 day
    }

/*
    Tier1Strategy tier1Strategy;
    Tier2Strategy tier2Strategy;
    Tier3Strategy tier3Strategy;
    Tier4Strategy tier4Strategy;
    Tier5Strategy tier5Strategy;
    Tier6Strategy tier6Strategy;
    Tier7Strategy tier7Strategy;
    Tier8Strategy tier8Strategy;
    Tier9Strategy tier9Strategy;
    Bottom_TStrategy bottom_TStrategy;


    constructor(
        address _tier1Strategy,
        address _tier2Strategy,
        address _tier3Strategy,
        address _tier4Strategy,
        address _tier5Strategy,
        address _tier6Strategy,
        address _tier7Strategy,
        address _tier8Strategy,
        address _tier9Strategy,
        address _bottom_TStrategy,
        WETH _weth, 
        uint64 _subscriptionId
    ) RandomGenerator(_subscriptionId) {
        tier1Strategy = Tier1Strategy(_tier1Strategy);
        tier2Strategy = Tier2Strategy(_tier2Strategy);
        tier3Strategy = Tier3Strategy(_tier3Strategy);
        tier4Strategy = Tier4Strategy(_tier4Strategy);
        tier5Strategy = Tier5Strategy(_tier5Strategy);
        tier6Strategy = Tier6Strategy(_tier6Strategy);
        tier7Strategy = Tier7Strategy(_tier7Strategy);
        tier8Strategy = Tier8Strategy(_tier8Strategy);
        tier9Strategy = Tier9Strategy(_tier9Strategy);
        bottom_TStrategy = Bottom_TStrategy(_bottom_TStrategy);

        weth = _weth;   //WETH(_weth);
        _admin = msg.sender;
        _defaultAuctionBidPeriod = 86400; // 1 day
    }

    function addNewStrategy(address _strategy, uint8 _identifier) external onlyOwner returns(address) {

        if(_identifier == 1){
            tier1Strategy = Tier1Strategy(_strategy);
        }
        if(_identifier == 2){
            tier2Strategy = Tier2Strategy(_strategy);
        }
        if(_identifier == 3){
            tier3Strategy = Tier3Strategy(_strategy);
        }
        if(_identifier == 4){
            tier4Strategy = Tier4Strategy(_strategy);
        }
        if(_identifier == 5){
            tier5Strategy = Tier5Strategy(_strategy);
        }
        if(_identifier == 6){
            tier6Strategy = Tier6Strategy(_strategy);
        }
        if(_identifier == 7){
            tier7Strategy = Tier7Strategy(_strategy);
        }
        if(_identifier == 8){
            tier8Strategy = Tier8Strategy(_strategy);
        }
        if(_identifier == 9){
            tier9Strategy = Tier9Strategy(_strategy);
        }
        if(_identifier == 10){
            bottom_TStrategy = Bottom_TStrategy(_strategy);
        }
    }
*/
/*
=====================================================================================================
=========================================== FUNCTIONS ===============================================
=====================================================================================================
*/

    /**
     * @notice Allows the deposits of NFTs into the pools
     * @dev The current implementation doesn't use the tokenWrapper Nft yet...
     * @param _nftAddress - The address of the NFT
     * @param _tokenId - The Nft's tokenId
     * @param _askPrice - The asking price of a seller
     */
    function depositNFT(
        address nftAddress_, 
        uint256 tokenId_, 
        uint128 askPrice_
        Tag prefferedPool_
    ) public { 
        require(nftAddress_ != address(0), "INVALID_ADDRESS");
        require(askPrice_ >= uint128(_priceLimit), "PRICE_IS_TOO_LOW");

        ///@dev If the Nft isn't part of the stored bluechip Nft's addresses,
        ///     the askPrice price must be less than/equal to the average price
        ///     gotten from a Nft oracle  - Hasn't been implemented yet
        /* if(nftAddress_ != _bluechips[nftAddress_]) {
            require(_askPrice <= DIAXfloor_MA)
        } */

        //solmate's transfer function
        ERC721(_nftAddress).safeTransferFrom(
            msg.sender, address(this), _tokenId
        );

        /*  bool successsful = IERC721(_nftAddress).transferFrom(
            msg.sender, address(this), _tokenId
        );
        require(successsful);
        */

        if(#0xprefferedListingPass[msg.sender]){
            _store(6, _#clubListIds[6], tokenId_, askPrice_, 0, prefferedPool_, 0x10 // - independent art, // poolStrategy,
            Status.OFF_LIST,
            payable(msg.sender),
            payable(0),
            nftAddress_);

            ++_#clubListIds[6];
        }
        
        Tag label = _addLabel(askPrice_);

        if(_0xclubA[nftAddress_]){
            _store(0, _#clubListIds[0], tokenId_, askPrice_, 0, label, #group[0], // poolStrategy,
            Status.OFF_LIST,
            payable(msg.sender),
            payable(0),
            nftAddress_);

            ++_#clubListIds[0];
        }

        if(_0xclubB[nftAddress_]){
            _store(1, _#clubListIds[1], tokenId_, askPrice_, 0, label, #group[1], // poolStrategy,
            Status.OFF_LIST,
            payable(msg.sender),
            payable(0),
            nftAddress_);

            ++_#clubListIds[1];
        }

        if(_0xclubC[nftAddress_]){
            _store(2, _#clubListIds[2], tokenId_, askPrice_, 0, label, #group[2], // poolStrategy,
            Status.OFF_LIST,
            payable(msg.sender),
            payable(0),
            nftAddress_);

            ++_#clubListIds[2];
        }

        if(_0xclubD[nftAddress_]){
            _store(3, _#clubListIds[3], tokenId_, askPrice_, 0, label, #group[3], // poolStrategy,
            Status.OFF_LIST,
            payable(msg.sender),
            payable(0),
            nftAddress_);

            ++_#clubListIds[3];
        }

        if(_0xclubE[nftAddress_]){
            _store(4, _#clubListIds[4], tokenId_, askPrice_, 0, label, #group[4], // poolStrategy,
            Status.OFF_LIST,
            payable(msg.sender),
            payable(0),
            nftAddress_);

            ++_#clubListIds[4];
        }

        if(_0xclubF[nftAddress_]){
            _store(5, _#clubListIds[5], tokenId_, askPrice_, 0, label, #group[5], // poolStrategy,
            Status.OFF_LIST,
            payable(msg.sender),
            payable(0),
            nftAddress_);

            ++_#clubListIds[5];
        }

    /*
        if(_0xclubG[nftAddress_] && !#0xprefferedListingPass[msg.sender]){

            _store(6, _#clubListIds[6], tokenId_, askPrice_, 0, label, #group[6], // poolStrategy,
            Status.OFF_LIST,
            payable(msg.sender),
            payable(0),
            nftAddress_);

            ++_#clubListIds[6];
        }
        
    */

        if(!_0xclubA[nftAddress_] && !_0xclubB[nftAddress_] && !_0xclubC[nftAddress_] && !_0xclubD[nftAddress_] && !_0xclubE[nftAddress_] && !_0xclubF[nftAddress_] && !_0xclubG[nftAddress_] && !#0xprefferedListingPass[msg.sender]){
            _store(6, _#clubListIds[6], tokenId_, askPrice_, 0, label, 0x00 //undefined, 
            // poolStrategy,
            Status.OFF_LIST,
            payable(msg.sender),
            payable(0),
            nftAddress_);

            ++_#clubListIds[6];
        }  


        emit NFTDeposited(
            _tokenId, 
            _askPrice, 
            0, 
            label, 
            Status.OFF_LIST, 
            payable(msg.sender), 
            payable(0), 
            payable(0), 
            _nftAddress
        );
    }

    function _store(
        uint256 n_,
        uint256 index_,
        uint256 tokenId_,
        uint256 askPrice_,
        uint256 soldPrice_,
        Tag label_,
        bytes4 clubId_,
        address pool_,
        Status status_,
        address owner_,
        address recipient_,
        address nftContract_
        ) internal {

            if(n_ == 0){
               Item storage item = _#clubAList[index_]; 
            }
            if(n_ == 1){
               Item storage item = _#clubBList[index_]; 
            }
            if(n_ == 2){
               Item storage item = _#clubCList[index_]; 
            }
            if(n_ == 3){
               Item storage item = _#clubDList[index_]; 
            }
            if(n_ == 4){
               Item storage item = _#clubEList[index_]; 
            }
            if(n_ == 5){
               Item storage item = _#clubFList[index_]; 
            }
            if(n_ == 6){
               Item storage item = _#clubGList[index_]; 
            }

            item.tokenId = tokenId_;
            item.askPrice = askPrice_;
            item.soldPrice = soldPrice_;
            item.label = label_;
            item.clubId = clubId_;
            //item.poolStrategy = pool_;
            item.status = status_;
            item.seller = owner_;
            item.nftRecipient = recipient_;
            item.nftContract = nftContract_;
    }

    function _sortOffList(uint256 itemId_, uint256 n_, Tag label_) internal returns(uint256[] calldata offList) {
           
        uint256 i; uint256 j;

        //declared an "offList" array to store the Ids of items 
        //with the "_label" and "OFF_LIST" tags
        offList = new uint256[](j);

        while(i < itemId_){
            if(n_ == 0){
               Item memory item = _#clubAList[i]; 
            }
            if(n_ == 1){
               Item memory item = _#clubBList[i]; 
            }
            if(n_ == 2){
               Item memory item = _#clubCList[i]; 
            }
            if(n_ == 3){
               Item memory item = _#clubDList[i]; 
            }
            if(n_ == 4){
               Item memory item = _#clubEList[i]; 
            }
            if(n_ == 5){
               Item memory item = _#clubFList[i]; 
            }
            if(n_ == 6 || n_ == 7){
               Item memory item = _#clubGList[i]; 
            }

            if(item.label == label_){
                if(item.status == Status.OFF_LIST){
                    offList[j] = i;
                    ++j;
                } 
            } 

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Starts a new auction
     * @dev Check for any excess of memory/gas used. 
     * @param label_ - The specific label(pool) to bid from
     * @param bid_ - The bid collateral(floorPrice) to pay
     */
    function startNewAuction(
        Tag label_, 
        uint256 bid_
    ) external payable {
        uint256 floorPrice = _getFloorPrice(label_);
        
        msg.value != 0 ?
        require(msg.value == floorPrice && bid_ == 0, "BID_IS_INVALID") :
        require(bid_ == floorPrice, "BID_IS_INVALID");

        uint256 clubListIds = _#clubListIds.length;
        uint256 rand = generateRandomObject(msg.sender, clubListIds);
        uint256 userAuctionBids = _#freeCollateral[msg.sender]._index;
        
        uint256[] memory items;
        bytes4 clb;
        
        for(uint256 i; i < clubListIds;){
            if(rand == i && rand != 6 && rand != 7){
                items = _sortOffList(_#clubListIds[i], rand, label_);
                clb = #group[i];
            }

           
            if(rand == 6 || rand == 7) {
                items = _sortOffList(_#clubListIds[6], rand, label_);
                clb = #group[6];
            }
            
            unchecked{++i;}
        }

        if(msg.value != 0){
            bool success = _takeCollateral(msg.value);
            required(success);
            bytes32 txHash = keccak256(abi.encode(c, address(0), msg.value));
            _#freeCollateral[msg.sender] = Collateral(
                userAuctionBids, 
                _#collateralHash[userAuctionBids][true] = txHash
            );
        } else {

            bool s = _takeCollateral(bid_);
            required(s);
            bytes32 txhash = keccak256(abi.encode(c, weth, bid_));
            _#freeCollateral[msg.sender] = Collateral(
                userAuctionBids, 
                _#collateralHash[userAuctionBids][true] = txhash
            );      
        }

        ++_#freeCollateral[msg.sender]._#index;
        
        uint256 c = _#claimsOnAuction;
        Auction memory a = #auctions[c];

        uint256 r = RandomGenerator.generateRandomObject(
            msg.sender, items
        );

        if(rand == 0){_#clubAList[r].status = Status.ON_LIST;}
        if(rand == 1){_#clubBList[r].status = Status.ON_LIST;}
        if(rand == 2){_#clubCList[r].status = Status.ON_LIST;}
        if(rand == 3){_#clubDList[r].status = Status.ON_LIST;}
        if(rand == 4){_#clubEList[r].status = Status.ON_LIST;}
        if(rand == 5){_#clubFList[r].status = Status.ON_LIST;}
        if(rand == 6 || rand == 7){_#clubGList[r].status = Status.ON_LIST;}
           
        #auctions[c] = Auction({
            highestBid: floorPrice,
            label: label_,
            club: clb,
            strategy: #0xstrategies[uint256(label_)],
            auctionTimeLeft: block.timestamp + #defaultAuctionBidPeriod,
            highestBidder: payable(msg.sender)
      //      param: " "
        });
                
        _#onAuction[c] = true;
        ++#claimsOnAuction;

        emit NewAuctionStarted(
            label_,
            a.club,
            c,
            a.auctionTimeLeft,
            a.highestBid
        );
    }

    
    /**
     * @notice Allows buyers to bid for a claim to an Nft
     * @dev Check for any excess of memory/gas used. Function is made public so any contract can call it
     * @param label_ - The specific label(pool) to bid from
     * @param target_ The specific claim to bid on
     * @param bid_ The bid price user is willing to pay
     */
    function bidForClaims(
        uint8 label_, 
        uint256 target_, 
        uint256 bid_
    ) public payable {
        require(#onAuction[target_], "NOT_ON_AUCTION");

        Auction storage c = #auctions[target_];
        
        require(uint8(c.label) == label_, "WRONG_POOL");
        
        ///@dev Checks if auction is still on - Auction time is 24 hrs
        uint32 timeLeft = _timeLeft(target_);

        if(timeLeft != 0){
            //Bid amount must meet the minimum bid increase 
            // percentage rate of current claim
            uint256 strategies = #0xstrategies.length;
            for(uint256 i; i <= strategies;){
                if(c.strategy == #0xstrategies[i]){
                    uint256 bipr = ITierStrategy(#0xstrategies[i]).fetchRate(....);

                    //ACTUAL
                    msg.value != 0 ?
                    require((msg.value - c.highestBid) >= (c.highestBid * bipr) && bid_ == 0, "BID_IS_INVALID") :
                    require((bid_ - c.highestBid) >= (c.highestBid * bipr), "BID_IS_INVALID");
                        
                    break;
                }
                unchecked{++i;}
            }

            Auction memory a;
            uint256 userAuctionBids = _#freeCollateral[msg.sender]._index;
            
            for(uint256 i; i < userAuctionBids;){
                (a, , uint256 amount) = abi.decode(
                    _#freeCollateral[msg.sender]._#collateralHash[i][true],
                    (Auction, , uint256)
                );
                
                if(a == c){
                    while(msg.value != 0){
                        uint256 collat = msg.value - amount;
                        bool success = _takeCollateral(collat);
                        required(success);
                        bytes32 txHash = keccak256(abi.encode(a, address(0), msg.value));
                        _#freeCollateral[msg.sender]._#collateralHash[i][true] = txHash;

                        break;
                    }

                    uint256 col = bid_ - amount;
                    bool s = _takeCollateral(col);
                    required(s);
                    bytes32 txhash = keccak256(abi.encode(a, weth, bid_));
                    _#freeCollateral[msg.sender]._#collateralHash[i][true] = txhash;

                    break;
                }
                unchecked{++i;}
            }

            //Check after loops to avoid immature storage change
            while(a != c){
                if(msg.value != 0){
                    bool success = _takeCollateral(msg.value);
                    required(success);
                    bytes32 txHash = keccak256(abi.encode(c, address(0), msg.value));
                    _#freeCollateral[msg.sender] = Collateral(
                        userAuctionBids, 
                        _#collateralHash[userAuctionBids][true] = txHash
                    );
                } else {

                bool s = _takeCollateral(bid_);
                required(s);
                bytes32 txhash = keccak256(abi.encode(c, weth, bid_));
                _#freeCollateral[msg.sender] = Collateral(
                    userAuctionBids, 
                    _#collateralHash[userAuctionBids][true] = txhash
                );
                
                }
                ++_#freeCollateral[msg.sender]._#index;
            }

            c.highestBid = bid_;
            c.highestBidder = msg.sender;

       
            emit NewBidMade(
                label_, 
                c, 
                timeLeft, 
                bid_, 
                msg.sender
            );
        } 
        
        revert BidFailed("AUCTION_HAS_ENDED");
    }  

    function _takeCollateral(uint256 col_) internal payable returns(bool){
        while(msg.value != 0){
            //Pays the fee to the contract
            (bool received, ) = payable(address(this)).call{
            value: col_,
            gas: 20000
            }("");
            require(received);
            return true;
        }

        bool sent = weth.transferFrom(msg.sender, address(this), col_); 
        //|| matic.transferFrom(msg.sender, address(this), col_);
        require(sent);
        return true;
    } 

    function withdrawCollateral(uint256 target_) external returns(bool){
        Auction storage c = #auctions[target_];

        Auction memory a;
        uint256 userAuctionBids = _#freeCollateral[msg.sender]._index;
            
        for(uint256 i; i < userAuctionBids;){
            (a, address token, uint256 amount) = abi.decode(
                _#freeCollateral[msg.sender]._#collateralHash[i][true], (Auction, address, uint256)
            );
                
            if(a == c){
                assert(a.highestBidder != msg.sender);
                _#freeCollateral[msg.sender]._#collateralHash[i][false];
                    
                bool success = _payback(amount, token);
                required(success);
                return true;
            }
            unchecked{++i;}
        }
    }

    function _payback(uint256 col_, address token_) internal returns(bool){
        while(token_ == address(0)){
            //Pays the fee to the contract
            (bool received, ) = msg.sender.call{
            value: col_,
            gas: 20000
            }("");
            require(received);
            return true;
        }

        bool sent = weth.transferFrom(address(this), msg.sender, col_); 
        //|| matic.transferFrom(address(this), msg.sender, col_);
        require(sent);
        return true;
    } 

    function withdrawAllCollateral() external returns(bool){
        uint256 userAuctionBids = _#freeCollateral[msg.sender]._index;

        uint256 ethCol;
        uint256 wethCol;

        for(uint256 i; i < userAuctionBids;){

            (Auction memory a, address token, uint256 amount) = abi.decode(_#freeCollateral[msg.sender]._#collateralHash[i][true], (Auction, address, uint256));

            if(a.highestBidder != msg.sender){
                while(token != address(0)){
                    wethCol += amount;
                }

                ethCol += amount;
                _#freeCollateral[msg.sender]._#collateralHash[i][false];
            }
             
            unchecked{++i;}
        }

        bool success = _payback(ethCol, address(0));
        required(success);
        bool s = _payback(wethCol, #weth);
        required(s);
        return true;
    }

    /**
     * @notice Assigns claiming rights to random itemIds
     * @dev Check if there's any excess use of memory/gas
     * @param label_ The pool label in an uint
     */
    function assignClaimingRights(uint8 label_) public {
        uint256 i;
        uint256 claimId = #_claimsOnAuction;
        while(i < claimId){
            if(#_auctions[i].highestBidder == msg.sender)
            if(uint8(@_auctions[i].label) == label_){
                if(_timeLeft(i) == 0){
                    uint256 randomId = _deliverItem(label_);
                    Item storage id = _items[randomId];
                    Auction memory c = @_auctions[i];

                    id.rightToClaim = c.highestBidder;
                    id.soldPrice = c.highestBid;
                    id.status = Status.OUT;
                }
            }

            unchecked {
                ++i;  
            }
        }

        emit ClaimingRightsAssigned(
            label_
        );
    }

    //escrow
    //1. transfer instead of approve
    //2. keep money in contract till the end
    //3. If a new bid comes, money becomes free to claim or added to.
    //4. Highest bidder's fee becomes locked.
    //5. How about gas fees? - well it's polygon - or we reward them with free gas when they increase bids - to encourage them to compete/ also incentivise the bids according to the weights and pools

    //claimFund(claim_)
    //claim = #_auction[claim_];
    //claim.lastBid = claim.highestBid;
    //if(claim.highestBidder != msg.sender && freeCollateralLocked[msg.sender][hash])
    //bytes32 hash = abi.encode(keccak256(#_auction[claim_], claim.lastBid));
    //mapping(address => mapping(bool => bytes32) hashRecord; hashRecord[msg.sender][true] = hash;
    //iten safe.   //hash index storage  id = 500... if(freeColllateral[msg.sender][hash])                      
    // (, uint256 amount_) = abi.decode(hash);
    //collateralLocked[msg.sender][hash] = false;
    //matic.transferFrom(msg.sender, amount_);
    // collaterals[address]
    // uint256 index -- first is 0, second: 1. increment

    //bytes32 hash = abi.encode(keccak256(_#auction[claim_], claim.lastBid));
    //uint256 userIndex = _#freeCollateral[msg.sender]._index;
    //_#freeCollateral[msg.sender] = Collateral(userIndex, _#collateralHash[userIndex][true] = hash)
    //index++; public 60 per user;
    // uint256 userTxs = _#freeCollateral[msg.sender]._index;
    // for(uint256 i; i < userTxs;){
    //    if(_#freeCollateral[msg.sender]._#collateralHash[i][true]){
    //    (, uint256 amount_) = abi.decode(_#collateralHash[i][true]);
    //     _#collateralHash[index][false];
    //      transferFrom(address(this), msg.sender, amount_)
    //      unchecked{i++;} 
    // }
    //}

    //withdrawable[msg.sender][byteH] = true;
    // mapping(address => Collateral) freeCollateral;
    // struct Collateral{ uint256 index, mapping(uint256 => mapping(bool => byte32))collateralHash }
    //if deposit... claim in place of byte32 
    //256 wrap the whole of the auction map in 

    
    //address currentHolder = claim.highestBidder;
    //_ping(currentHolder) - push notification./or email
    //

    ///@notice Allows highest bidder to claim their Nft
    ///@dev Check if there's any excess use of memory/gas 
    ///@param _label The pool label in an uint
    ///@param _claim The Id of the auction won
    ///@param _nftRecipient A recipient address where the Nft would be transferred to
    function claimNft(
        uint8 label_, 
        uint256 claim_, 
        address nftRecipient_
    ) external {
        Auction memory c = #_auctions[claim_];
        
        ///@dev Checks if auction is still on - Auction time is 24 hrs
        if(_timeLeft(claim_) != 0) revert("still on");

        require(msg.sender == c.highestBidder, "WRONG_AUCTION_ID");
        //assignClaimi

        uint256 clubListIds = #_clubListIds.length;
        uint256 itemList;

        for(uint256 i; i < clubListIds;){
            if(c.club == #group[i]){
                itemList = _clubListIds[i];
                break;
            }
            unchecked{++i;}
        }

        uint256 randomId = _deliverItem(itemList, 0, label_);

        uint256 i;
        while(i < itemList){
            
        if(label_ == 0){
            Item storage item = #_clubAList[randomId];
                uint256 randomId = _deliverItem(label_);
                Item storage id = _items[randomId];
            item.status = Status.OUT;

                if(uint8(item.label) == _label && item.status == Status.ON_LIST){
                    uint256 randomId = _deliverItem(label_);
                    Item storage id = _items[randomId];
                    item.status = Status.OUT;
                }
            }
            if(label_ == 1){Item memory item = #_clubBList[i];}
            if(label_ == 2){Item memory item = #_clubCList[i];}
            if(label_ == 3){Item memory item = #_clubDList[i];}
            if(label_ == 4){Item memory item = #_clubEList[i];}
            if(label_ == 5){Item memory item = #_clubFList[i];}
            if(label_ == 6 || label_ == 7){Item memory item = #_clubGList[i];}

            if(uint8(_items[i].label) == _label && 
            item.status == Status.OUT){
                
                if(item.rightToClaim == claim.highestBidder && 
                item.soldPrice == claim.highestBid){

                    uint256 userBalance = payable(msg.sender).balance;
        
                    if(userBalance < item.soldPrice){
                        weth.safeApprove(address(this), item.soldPrice);
                    }
                 
                    /*
                    (bool checked) = IERC20(_tokenAddress).approve(
                        address(this), item.soldPrice
                    );
                    require(checked);
                    */
                    
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

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
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
    function _addLabel(uint256 askPrice_) internal returns(Tag){
        //Item storage item = _items[_item];
        uint256[10] memory priceTags = _priceTags;
 
        if(askPrice_ < priceTags[0]){
            return Tag.TIER_ONE;  //tier1Strategy;
        }
        if(item.askPrice >= priceTags[1]){
            return Tag.TIER_TWO; //tier2Strategy;  
        } 
        if(item.askPrice >= priceTags[2]){
            return Tag.TIER_THREE; //tier3Strategy;
        } 
        if(item.askPrice >= priceTags[3]){
            return Tag.TIER_FOUR; // tier4Strategy;
        } 
        if(item.askPrice >= priceTags[4]){
            return Tag.TIER_FIVE; //tier5Strategy;
        }  
        if(item.askPrice >= priceTags[5]){
            return Tag.TIER_SIX; //tier6Strategy;
        } 
        if(item.askPrice >= priceTags[6]){
            return Tag.TIER_SEVEN; //tier7Strategy;
        } 
        if(item.askPrice >= priceTags[7]){
            return Tag.TIER_EIGHT; //tier8Strategy;
        } 
        if(item.askPrice >= priceTags[8]){
            return Tag.TIER_NINE; //tier9Strategy;
        } 
        if(item.askPrice >= priceTags[9]){
            return Tag.BOTTOM_T; //bottom_TStrategy;
        }
        
       // item.label = Tag.TIER_ONE;

       // return item.label;
    }

    
    ///@dev Checks if auction is still on - Auction time is 24 hrs
    ///     The wrapped block.timestamp in uint32 compares with the last 4 bytes 
    ///     of the entire timestamp.
    function _timeLeft(uint256 _claim) internal returns(uint32) {
        Auction storage claim = _auctions[_claim];
        
        //Still skeptical about this comparison
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
    function _getFloorPrice(Tag _label) private view returns(uint256){
       uint256 i; uint256 num; uint256 amount;
       while(i < _itemId){
        Item memory item = _items[i];
        if(item.label == _label){
            if(item.status == Status.OFF_LIST){
                num = num + 1;
                amount = amount + item.askPrice;
            }
            
            while(i < _claimsOnAuction){
                Auction memory claim = _auctions[i];
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
    function _deliverItem(uint256 itemId_, uint256 n_, Tag label_) internal returns(uint256[] calldata onList) {
           
        uint256 i; uint256 j;

        //declared an "onList" array to store the Ids of items 
        //with the "_label" and "ON_LIST" tags
        onList = new uint256[](j);

        while(i < itemId_){
            if(n_ == 0){
               Item memory item = _clubAList[i]; 
            }
            if(n_ == 1){
               Item memory item = _clubBList[i]; 
            }
            if(n_ == 2){
               Item memory item = _clubCList[i]; 
            }
            if(n_ == 3){
               Item memory item = _clubDList[i]; 
            }
            if(n_ == 4){
               Item memory item = _clubEList[i]; 
            }
            if(n_ == 5){
               Item memory item = _clubFList[i]; 
            }
            if(n_ == 6 || n_ == 7){
               Item memory item = _clubGList[i]; 
            }


            if(uint8(item.label) == label_){
                if(item.status == Status.ON_LIST){
                    onList[j] = i;
                    ++j;
                }
            }

            unchecked {
                ++i;  
            }
        }

        uint256 rand = RandomGenerator.generateRandomObject(
            msg.sender, itemsList
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
        Item storage item = _items[_item];

        item.nftRecipient = _getNftRecipient(_item, _nftRecipient);

        _payFeeAndSeller(item);

        ///@dev Uses safeTransferFrom to check if "item.nftRecipient" 
        ///     can receive Nft before execution
        ERC721(item.nftContract).safeTransferFrom(
            address(this),
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
        (bool received, ) = payable(address(this)).call{
            value: _fee,
            gas: 20000
        }("");

 //       require(received);
        if(!received){  //_tokenAddress.safeTransfer(address(this), _fee);
            (bool done) = weth.transfer(  //use transfer except approve function don't work
                address(this), _fee);
            require(done);
        }

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
                //_tokenAddress.safeTransferFrom(msg.sender, _item.seller, _amount) || _tokenAddress.safeTransfer(address(this), _amount);
                (bool paid) = weth.transferFrom(
                    msg.sender, _item.seller, _amount) ||
                        weth.transfer(address(this), _amount
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
        while(i < _claimsOnAuction){
           _auctions[i] = _auctions[i + 1]; 
            unchecked {
                i++;  
            }
           delete _auctions[i];
          _claimsOnAuction = _claimsOnAuction - 1; 
        }   
    } 

/*
=====================================================================================================
============================================= SETTERS ===============================================
=====================================================================================================    
*/    

    ///@dev Only Admin can update priceTag 
    ///@return _priceTags[_priceTagId]
    function setPriceTag(
        uint8 _priceTagId, 
        uint256 _value
    ) ifAdmin external returns(uint256) {
        require(_value != 0, "INVALID_INPUT");
        _priceTags[_priceTagId] = _value * 1e18;
        return _priceTags[_priceTagId];
    }

    ///@dev Only Admin can update priceLimit 
    ///@return _priceLimit
    function setPriceLimit(
        uint64 _value
    ) ifAdmin external returns(uint64) {
        require(_value != 0, "INVALID_INPUT");
        _priceLimit = _value;
        return _priceLimit;
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

    function getFloorPrice(Tag _label) public view returns(uint256){
        return _getFloorPrice(_label);
    }
    
    function _getMinBidIncreasePercentage() internal view returns (uint64) {
        return _minBidIncreasePercentage;
    } 

    function getAuctionBidPeriod() public view returns (uint32){
        return _defaultAuctionBidPeriod;
    }

} 
/*
contract AccessPool {
    function see(address payable addr) public returns(bool, bytes memory) {
        FairWheel fair = FairWheel(addr);
        bytes memory txd = abi.encodeWithSignature("setPriceLimit(uint64)", 20);

        return address(fair).call(txd);
        //return address(fair).call{setPriceLimit(20)};
    }
}*/
