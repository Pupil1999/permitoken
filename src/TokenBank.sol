// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenBank {
    address public currency;
    mapping(address => uint256) balanceOf;

    constructor(address ptkAddr) {
        currency = ptkAddr;
    }

    function permitDeposit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(spender == address(this), "not transfer to this bank");

        IERC20Permit(currency).permit(owner, spender, value, deadline, v, r, s);

        balanceOf[owner] += value;
    }

    function withdraw(
        uint256 amount
    ) external {
        require(balanceOf[msg.sender] >= amount, "no enough balance");
        IERC20(currency).transfer(msg.sender, amount);
        balanceOf[msg.sender] -= amount;
    }
}