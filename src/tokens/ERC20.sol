// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ERC20 as ERC20OpenZeppelin } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20 is ERC20OpenZeppelin {
    uint8 private _customDecimals;

    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20OpenZeppelin(name, symbol) {
        _customDecimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _customDecimals;
    }
}
