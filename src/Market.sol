// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PermitUtil.sol";

contract Market {
    address public currency; // ERC20 contract
    address public goods;    // ERC721 contract

    constructor(
        address erc20_,
        address erc721_
    ) {
        currency = erc20_;
        goods = erc721_;
    }

    // function permitBuy(
    //     address owner,
    //     address buyer,
    //     uint256 tokenId,
    //     uint256 payment,
    //     uint256 deadline,
    //     PermitUtil.Signature memory erc20PaymentSig,
    //     PermitUtil.Signature memory erc721OnMarketSig,
    //     PermitUtil.Signature memory erc721BuySig
    // ) external {
    //     if(block.timestamp > deadline)
    //         revert("buying permission expired");

        

    // }
}