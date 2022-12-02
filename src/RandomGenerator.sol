//SPDX-License-Identifier: MIT
pragma solidity^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {PoolStorage} from './PoolStorage.sol';

/**
 * @title RandomGenerator
 * @dev The random object generator for FairWheel Nft Marketplace that inherits chainlink's VRF.
 * This contract receives values in an array and picks a random value from the array
 * This contract might be incomplete/unoptimized and could need some other useful variables
 */

contract RandomGenerator is VRFConsumerBaseV2, PoolStorage {
    uint8 private constant ROLL_IN_PROGRESS = 0x22;

    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Goerli coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 s_keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 40,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 40000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 1 random value in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    address s_owner;

    ///@dev An array of objects
    uint256[] _objectsId;

    uint256[] public s_randomWords;

    // map callers to requestIds
    mapping(uint256 => address) private s_callers;
    // map vrf results to callers
    mapping(address => uint256) private s_results;

    event RandRequested(uint256 indexed requestId, address indexed caller);
    event RandGenerated(uint256 indexed requestId, uint256 indexed result);

    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @dev NETWORK: Goerli
     *
     * @param subscriptionId_ subscription id that this consumer contract can use
     */
    constructor(uint64 subscriptionId_) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId_;
    }

    /**
     * @notice Requests randomness
     * @dev Warning: if the VRF response is delayed, avoid calling requestRandomness repeatedly
     * as that would give miners/VRF operators latitude about which VRF response arrives first.
     * @dev You must review your implementation details with extreme care.
     *
     * @param _caller address of the roller
     */
    function requestRandomness(address _caller) internal returns (uint256 requestId) {
        require(s_results[_caller] == 0, "Already called");
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        s_callers[requestId] = _caller;
        s_results[_caller] = ROLL_IN_PROGRESS;
        emit RandRequested(requestId, _caller);
    }

    /**
     * @notice Callback function used by VRF Coordinator to return the random number to this contract.
     *
     * @dev Some action on the contract state should be taken here, like storing the result.
     * @dev WARNING: take care to avoid having multiple VRF requests in flight if their order of arrival would result
     * in contract states with different outcomes. Otherwise miners or the VRF operator would could take advantage
     * by controlling the order.
     * @dev The VRF Coordinator will only send this function verified responses, and the parent VRFConsumerBaseV2
     * contract ensures that this method only receives randomness from the designated VRFCoordinator.
     *
     * @param requestId uint256
     * @param randomWords  uint256[] The random result returned by the oracle.
     */
    function fulfillRandomWords(
        uint256 requestId, 
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
        uint256 objectValue = (s_randomWords[0] % getObjectsNum()) + 1;
        s_results[s_callers[requestId]] = objectValue;
        emit RandGenerated(requestId, objectValue);
    }

    function getObjectsNum() private view returns(uint256) {
        return _objectsId.length;
    } 

    /**
     * @notice Generates a random object(uint) from a list of an array passed into the function
     * @param _searcher address of the sender
     * @param _itemList the array of values where a random value will be generated from
     * @return rand a random value
     */
    function generateRandomObject(
        address _searcher, 
        uint[] memory _itemList
    ) virtual internal returns(uint256){
        _objectsId = _itemList;

        requestRandomness(_searcher);
        uint256 rand = checkStatus(_searcher);

        _removeObjects();
        s_results[_searcher] = 0;
        
        return rand;
    }

    /**
     * @notice Get the random object assigned to the receiver
     * @param _receiver address
     * @return object id as an uint
     */
    function checkStatus(address _receiver) internal view returns(uint256) {
        require(s_results[_receiver] != 0, 'Rand not requested');
        require(s_results[_receiver] != ROLL_IN_PROGRESS, 'Roll in progress');
        return getStatus(s_results[_receiver]);
    }

    /**
     * @notice Get the object through receiver's id
     * @param _id uint256
     * @return objectId id as an uint
     */
    function getStatus(uint256 _id) private view returns (uint256){ //DataTypes.Item memory) {
        return _objectsId[_id];
    }

    function _removeObjects() internal {
        uint256[] storage objectArray = _objectsId;

        uint i;
        while(i < objectArray.length){
            objectArray.pop();
            unchecked {
                i++;  
            }
            //objectArray.pop();
        }   
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}
