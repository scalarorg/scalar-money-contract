// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ProxyOracle } from "@abracadabra/oracles/ProxyOracle.sol";
import { FixedPriceOracle } from "@abracadabra/oracles/FixedPriceOracle.sol";
import { DegenBox } from "@abracadabra/DegenBox.sol";
import { BaseScript } from "./Base.s.sol";
import { IMintableBurnableERC20 } from "../src/interfaces/IMintableBurnableERC20.sol";
import { console2 } from "forge-std/console2.sol";

interface IDegenBox {
    function deposit(
        IMintableBurnableERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    )
        external
        payable
        returns (uint256 amountOut, uint256 shareOut);
}

contract PrepareLiquidityScript is BaseScript {
    address public constant SUSD = 0xb3Ce4Baee3c5F7F17aB3f751bc12b7da1Ae10644;
    address public constant SBTC = 0x29e596F7911372A707454fabaC5De33a475Bb9E9;
    address public constant DEGEN_BOX = 0xC36b440D04D56a558B1bEE1Ae9723EB27e933837;
    address public constant SBTC_MARKET = 0xA72aaB00A7eE79A4d70F21071937881bd252AeB1;

    function run() external broadcast {
        console2.log("Broadcaster:", msg.sender);
        IMintableBurnableERC20(SBTC).mint(msg.sender, 1000 ether);
        // IMintableBurnableERC20(SUSD).mint(msg.sender, 1e9 ether);
        // IDegenBox(DEGEN_BOX).deposit(IMintableBurnableERC20(SUSD), msg.sender, SBTC_MARKET, 1e9 ether, 0);
    }
}
