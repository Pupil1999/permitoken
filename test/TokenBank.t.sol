// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PermitToken.sol";
import "../src/TokenBank.sol";
import "../src/PermitUtil.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TokenBankTest is Test {
    PermitToken public token;
    TokenBank public bank;
    PermitUtil public util;

    function setUp() public {
        token = new PermitToken();
        bank = new TokenBank(address(token));
        util = new PermitUtil();
    }

    function test_permitDeposit() public {
        address owner = vm.addr(0x123);
        address spender = address(bank);
        token.transfer(owner, 10e18);

        // construct the permission message
        PermitUtil.PermitERC20 memory permission = PermitUtil.PermitERC20({
            owner: owner,
            spender: spender,
            value: 1e18,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 permitHash = util.hashStruct(permission);

        bytes32 msgHash = MessageHashUtils.toTypedDataHash(token.DOMAIN_SEPARATOR(), permitHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0x123, msgHash);

        // Invoke the permit function in bank, which will invoke permit in erc20
        bank.permitDeposit(owner, spender, 1e18, 1 days, v, r, s);
        assertEq(token.balanceOf(spender), 1e18);
        assertEq(token.balanceOf(owner), 9e18);
    }

    function test_replayAttack(address attacker) public {
        address owner = vm.addr(0x123);
        address spender = address(bank);
        token.transfer(owner, 10e18);

        // construct the permission message
        PermitUtil.PermitERC20 memory permission = PermitUtil.PermitERC20({
            owner: owner,
            spender: spender,
            value: 1e18,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 permitHash = util.hashStruct(permission);

        bytes32 msgHash = MessageHashUtils.toTypedDataHash(token.DOMAIN_SEPARATOR(), permitHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0x123, msgHash);

        // Invoke the permit function in bank, which will invoke permit in erc20
        bank.permitDeposit(owner, spender, 1e18, 1 days, v, r, s);
        vm.expectRevert();
        vm.prank(attacker);
        bank.permitDeposit(owner, spender, 1e18, 1 days, v, r, s);
    }

    function test_overTime() public {
        address owner = vm.addr(0x123);
        address spender = address(bank);
        token.transfer(owner, 10e18);

        // construct the permission message
        PermitUtil.PermitERC20 memory permission = PermitUtil.PermitERC20({
            owner: owner,
            spender: spender,
            value: 1e18,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 permitHash = util.hashStruct(permission);

        bytes32 msgHash = MessageHashUtils.toTypedDataHash(token.DOMAIN_SEPARATOR(), permitHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0x123, msgHash);

        vm.warp(2 days);
        vm.expectRevert(abi.encodeWithSignature("ERC2612ExpiredSignature(uint256)", 1 days));
        // Invoke the permit function in bank, which will invoke permit in erc20
        bank.permitDeposit(owner, spender, 1e18, 1 days, v, r, s);
    }
}