// SPDX-License-Identifier: MIT

// @dev This contract has been adapted to fit with dappTools
pragma solidity ^0.8.0;

import "@solmate/tokens/ERC721.sol";
/*
interface ERC677Receiver {
    function onTokenTransfer(
        address _sender,
        uint256 _value,
        bytes memory _data
    ) external;
}*/

contract MockNFT is ERC721 {
    
    uint256 constant INITIAL_SUPPLY = 10000;

    constructor() ERC721("MockToken", "MKT") {
        _mintAllToDeployer();
    }

  /*  event Transfer(
        address indexed from,
        address indexed to,
        uint256 id,
        bytes data
    );*/

    function _mintAllToDeployer() internal virtual{
        uint256 i;
        while(i <= INITIAL_SUPPLY){
            _mint(msg.sender, i);
            unchecked{i++;}
        }
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

        emit Transfer(address(0), to, id);
    }

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
