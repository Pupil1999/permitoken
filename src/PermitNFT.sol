// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract PermitNFT is ERC721("PermitNFT", "PNFT"), EIP712("PermitNFT", "1") {
    uint256 nextTokenId;
    mapping(bytes32 => bool) isOnMarketPermissionUsed;

    bytes32 private constant PERMIT_NFTONMARKET_TYPEHASH =
        keccak256("Permit(address owner,uint256 tokenId,uint256 value,address market)");

    constructor() {
        nextTokenId = 0;
    }

    function DOMAIN_SEPARATOR() external view returns(bytes32){
        return _domainSeparatorV4();
    }

    function mint() public {
        _mint(msg.sender, nextTokenId++);
    }

    // Approve some token to NFT market by signing a signature.
    function permit(
        address owner,
        uint256 tokenId,
        uint256 value,
        address market,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(market == msg.sender, "caller is not market");

        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_NFTONMARKET_TYPEHASH,
                owner,
                tokenId,
                value,
                market
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        if( isOnMarketPermissionUsed[hash] )
            revert("already put on market");
        isOnMarketPermissionUsed[hash] = true;
        address signer = ecrecover(hash, v, r, s);
        if( signer != owner )
            revert("not owner approving token to market");

        _approve(market, tokenId, address(0));
    }
}