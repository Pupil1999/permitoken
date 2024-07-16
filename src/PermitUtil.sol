// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PermitUtil {
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // This is defined in ERC20 contracts that implemented EIP712.
    struct PermitERC20 {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    function hashStruct(
        PermitERC20 memory info
    ) external pure returns(bytes32){
        return keccak256(abi.encode(
            PERMIT_TYPEHASH,
            info.owner,
            info.spender,
            info.value,
            info.nonce,
            info.deadline
        ));
    }
    
}