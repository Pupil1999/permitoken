// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PermitNFT is ERC721("PermitNFT", "PNFT") {
    uint256 nextTokenId;

    constructor() public {
        nextTokenId = 0;
    }

    function mint() public {
        _mint(msg.sender, nextTokenId++);
    }
}