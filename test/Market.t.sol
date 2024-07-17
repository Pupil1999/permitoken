// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Market.sol";
import "../src/PermitToken.sol";
import "../src/PermitNFT.sol";
import "../src/PermitUtil.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MarketTest is Test {
    PermitToken public currency;
    PermitNFT public goods;
    Market public market;
    PermitUtil public util;

    function setUp() public {
        currency = new PermitToken();
        goods = new PermitNFT();
        market = new Market(address(currency), address(goods));
        util = new PermitUtil();
    }

    function test_mint() public {
        vm.prank(address(0x123));
        goods.mint();
        assertEq(goods.ownerOf(0), address(0x123));
    }

    function test_buyNFT() public {
        address owner = vm.addr(0x123);
        address buyer = vm.addr(0x456);
        uint256 tokenId = 0;
        uint256 value = 1e18;
        uint256 payment = value;
        uint256 buyingDeadline = 1 days;
        uint256 paymentDeadline = 1 days;

        // Getting signature for payment
        PermitUtil.PermitERC20 memory paymentStruct = PermitUtil.PermitERC20({
            owner: buyer,
            spender: owner,
            value: payment,
            nonce: 0,
            deadline: paymentDeadline
        });

        bytes32 paymentStructHash = util.hashStruct(paymentStruct);
        bytes32 paymentHash = MessageHashUtils.toTypedDataHash(
            currency.DOMAIN_SEPARATOR(), // this will be verified in erc20 contract
            paymentStructHash
        );
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(0x456, paymentHash);
        PermitUtil.Signature memory paymentSig = PermitUtil.Signature({
            v: v1,
            r: r1,
            s: s1
        });

        // Getting signature for putting nft on market
        PermitUtil.PermitERC721OnMarket memory onMarketStruct 
            = PermitUtil.PermitERC721OnMarket({
            owner: owner,
            tokenId: tokenId,
            value: value,
            market: address(market)
        });

        bytes32 onMarketStructHash = util.hashOnMarket(onMarketStruct);
        bytes32 onMarketHash = MessageHashUtils.toTypedDataHash(
            goods.DOMAIN_SEPARATOR(),
            onMarketStructHash
        );
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(0x123, onMarketHash);
        PermitUtil.Signature memory onMarketSig = PermitUtil.Signature({
            v: v2,
            r: r2,
            s: s2
        });

        // Getting signature for buying
        PermitUtil.PermitBuyNFT memory permitBuyStruct = PermitUtil.PermitBuyNFT({
            owner: owner,
            buyer: buyer,
            tokenId: tokenId,
            deadline: buyingDeadline
        });

        bytes32 permitBuyStructHash = util.hashPermitBuy(permitBuyStruct);
        bytes32 permitBuyHash = MessageHashUtils.toTypedDataHash(
            market.DOMAIN_SEPARATOR(),
            permitBuyStructHash
        );

        (uint8 v3, bytes32 r3, bytes32 s3) = vm.sign(0x123, permitBuyHash);
        PermitUtil.Signature memory permitBuySig = PermitUtil.Signature({
            v: v3,
            r: r3,
            s: s3
        });

        // Mint a NFT token with id 0
        vm.prank(owner);
        goods.mint();

        // Prepare some erc20 money for buyer
        currency.transfer(buyer, 10e18);

        // the balances and nft owner before buying
        assertEq(currency.balanceOf(buyer), 10e18);
        assertEq(goods.ownerOf(0), owner);

        // Submitting three signatures to permitBuy in market.
        market.permitBuy(
            owner, 
            buyer, 
            tokenId, 
            value, 
            payment, 
            buyingDeadline, 
            paymentDeadline, 
            paymentSig,
            onMarketSig,
            permitBuySig
        );

        assertEq(currency.balanceOf(buyer), 9e18);
        assertEq(currency.balanceOf(owner), 1e18);
        assertEq(goods.ownerOf(0), buyer);
    }
}