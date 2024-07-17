// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PermitUtil.sol";
import "./PermitToken.sol";
import "./PermitNFT.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Market is EIP712("NFTMarket", "1"){
    address public currency; // ERC20 contract
    address public goods;    // ERC721 contract
    mapping(bytes32 => bool) public isBuyingUsed;

    bytes32 private constant PERMIT_TOKENPAYMENT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 private constant PERMIT_NFTONMARKET_TYPEHASH =
        keccak256("Permit(address owner,uint256 tokenId,uint256 value,address market)");

    bytes32 private constant PERMIT_NFTBUY_TYPEHASH =
        keccak256("Permit(address owner,address buyer,uint256 tokenId,uint256 deadline)");

    constructor(address erc20_, address erc721_) {
        currency = erc20_;
        goods = erc721_;
    }

    function DOMAIN_SEPARATOR() public view returns(bytes32){
        return _domainSeparatorV4();
    }

    function permitBuy(
        address owner, // owner of the erc721 token to be sold
        address buyer, // who wants to the erc721 token
        uint256 tokenId, // the erc721 token identified by its id
        uint256 value, // the value of erc721 token set by the owner
        uint256 payment, // the amount paid by the buyer
        uint256 buyingDeadline, // the deadline of the buying certification
        uint256 paymentDeadline, // the deadline of payment
        PermitUtil.Signature memory erc20PaymentSig,
        PermitUtil.Signature memory erc721OnMarketSig,
        PermitUtil.Signature memory erc721BuySig
    ) external {
        if(value != payment)
            revert("the two sides should negotiate a same price of the good");

        if(block.timestamp > buyingDeadline)
            revert("buying permission expired");

        // Verify that owner allowed the buyer to buy the NFT
        bytes32 structBuyingPermissionHash = keccak256(
            abi.encode(
                PERMIT_NFTBUY_TYPEHASH,
                owner,
                buyer,
                tokenId,
                buyingDeadline
            )
        );
        bytes32 hash = _hashTypedDataV4(structBuyingPermissionHash);
        if ( isBuyingUsed[hash] )
            revert("repeated buying");
        isBuyingUsed[hash] = true;
        address signer = ECDSA.recover(
            hash,
            erc721BuySig.v,
            erc721BuySig.r,
            erc721BuySig.s
        );
        if(signer != owner)
            revert("not permitted by owner");

        // For now, the buyer is authenticated to buy the token.
        // But we still need to check the payment.
        _buyNFT(
            owner, buyer, tokenId, payment, paymentDeadline,
            erc20PaymentSig, erc721OnMarketSig
        );
    }

    function _buyNFT(
        address owner,
        address buyer,
        uint256 tokenId,
        uint256 value, // also equal to payment
        uint256 paymentDeadline,
        PermitUtil.Signature memory erc20PaymentSig,
        PermitUtil.Signature memory erc721OnMarketSig
    ) internal {
        // Once successfully invoked, the erc721 token will be approved to the market.
        (bool suc1, ) = goods.call(
            abi.encodeWithSignature("permit(address,uint256,uint256,address,uint8,bytes32,bytes32)", 
            owner,
            tokenId,
            value,
            address(this),
            erc721OnMarketSig.v,
            erc721OnMarketSig.r,
            erc721OnMarketSig.s
            )
        );
        require(suc1, "on market permit failed");

        // Once successfully invoked, the erc20 payment will be sent to the owner.
        (bool suc2, ) = currency.call(
            abi.encodeWithSignature(
                "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)", 
                buyer,
                owner,
                value,
                paymentDeadline,
                erc20PaymentSig.v,
                erc20PaymentSig.r,
                erc20PaymentSig.s
            )
        );
        require(suc2, "erc20 payment permit failed");

        IERC721(goods).safeTransferFrom(owner, buyer, tokenId);
    }
}