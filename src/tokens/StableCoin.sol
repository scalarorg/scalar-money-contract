// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IBentoBoxV1, IERC20 } from "@abracadabra/interfaces/IBentoBoxV1.sol";
import { ERC20 } from "@BoringSolidity/ERC20.sol";

import { BoringOwnable } from "@BoringSolidity/BoringOwnable.sol";
import { BoringMath } from "@BoringSolidity/libraries/BoringMath.sol";

contract StableCoin is ERC20, BoringOwnable {
    using BoringMath for uint256;

    error SendToZeroAddress();
    error NotEnoughBalance();

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = 0;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        if (to == address(0)) revert SendToZeroAddress();

        totalSupply = totalSupply + amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function mintToBentoBox(address clone, uint256 amount, IBentoBoxV1 bentoBox) public onlyOwner {
        mint(address(bentoBox), amount);
        bentoBox.deposit(IERC20(address(this)), address(bentoBox), clone, amount, 0);
    }

    function burn(uint256 amount) public {
        if (amount > balanceOf[msg.sender]) revert NotEnoughBalance();

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
