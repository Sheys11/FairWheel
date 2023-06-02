// SPDX-License-Identifier: MIT

// @dev This contract has been adapted to fit with dappTools
pragma solidity ^0.8.0;

import {ERC721} from "@solmate/tokens/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
/*
interface ERC677Receiver {
    function onTokenTransfer(
        address _sender, 
        uint256 _value,
        bytes memory _data
    ) external;
}*/

contract MockNFT is ERC721 {
    using Strings for uint256;

    string public baseURI;
    
    uint256 constant INITIAL_SUPPLY = 10000;

    //mapping(uint256 => address) public ownr;

    constructor(string memory _baseURI) ERC721("MockToken", "MKT") {
        _mintAllToDeployer();
        baseURI = _baseURI;
    }

  /*  event Transfer(
        address indexed from,
        address indexed to,
        uint256 id,
        bytes data
    );*/

    function ownerOf(uint256 id) public view virtual override returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function _mintAllToDeployer() internal virtual{
        uint256 i;
        while(i <= INITIAL_SUPPLY){
            _mint(msg.sender, i);
            unchecked{i++;}
        }
    }

     function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _ownerOf[tokenId] != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

/*
    function mint(address to, uint256 id) public virtual{
        require(id <= INITIAL_SUPPLY, "MINT_LIMIT_REACHED");
        _mint(msg.sender, id);
    }
*/

    function _mint(address to, uint256 id) internal virtual override {
        require(to != address(0), "INVALID_RECIPIENT");
        require(id <= INITIAL_SUPPLY, "MINT_LIMIT_REACHED");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

   //     ownr[id] = _ownerOf[id];

        emit Transfer(address(0), to, id);
    }

  /*  function _update(uint256 id) internal {
        ownr[id] = _ownerOf[id];
    }

  /   function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        ownr[id] = _ownerOf[id];

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721ModTokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721ModTokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual override {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721ModTokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721ModTokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }


    function _burn(uint256 id) internal virtual override {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];
        delete ownr[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    } /

    /*
     * @dev transfer token to a contract address with additional data if the recipient is a contract.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @param _data The extra data to be passed to the receiving contract.
     */
/*    function transferAndCall(
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) public virtual returns (bool success) {
        super.transferFrom(_from, _to, _id);
        // emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _id, _data);
        if (isContract(_to)) {
            contractFallback(_to, _id, _data);
        }
        return true;
    }

    // PRIVATE

    function contractFallback(
        address _to,
        uint256 _id,
        bytes memory _data
    ) private {
        ERC677Receiver receiver = ERC677Receiver(_to);
        receiver.onTokenTransfer(msg.sender, _id, _data);
    }

    function isContract(address _addr) private view returns (bool hasCode) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        return length > 0;
    }*/
}
