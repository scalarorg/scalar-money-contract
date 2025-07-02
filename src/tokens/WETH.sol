// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ERC20 } from "./ERC20.sol";

contract WETH is ERC20 {
    error InsufficientBalance();

    constructor() ERC20("WETH", "WETH", 18) { }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        if (balanceOf(msg.sender) < amount) revert InsufficientBalance();
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    function mint(address account, uint256 amount) public override {
        _mint(account, amount);
    }

    receive() external payable {
        deposit();
    }
}
