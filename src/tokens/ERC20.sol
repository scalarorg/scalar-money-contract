// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ERC20 as ERC20OpenZeppelin } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { BoringOwnable } from "@BoringSolidity/BoringOwnable.sol";
import { IMintableBurnableERC20 } from "../interfaces/IMintableBurnableERC20.sol";

contract ERC20 is IMintableBurnableERC20, ERC20OpenZeppelin, BoringOwnable {
    uint8 private _customDecimals;

    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20OpenZeppelin(name, symbol) {
        _customDecimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _customDecimals;
    }

    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public virtual onlyOwner {
        _burn(from, amount);
    }
}
