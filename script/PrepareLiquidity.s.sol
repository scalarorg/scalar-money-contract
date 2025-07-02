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
    ) external payable returns (uint256 amountOut, uint256 shareOut);
}

contract PrepareLiquidityScript is BaseScript {
    address public constant SBTC = 0x3cBb62d23120918019037b51a1e513FdAAddDE3f;
    address public constant SUSD = 0x124C4a03C08601a0625bb5b543E58b2a61fCE770;
    address public constant DEGEN_BOX = 0xB97DfDF8b0692a2A9aff2fc089E120b05410C7BD;
    address public constant SBTC_MARKET = 0x962dbc8209Eb083Ed71C38cf4d7482c7C947cF14;

    function run() external broadcast(){
        console2.log("Broadcaster:", msg.sender);
        // IMintableBurnableERC20(SBTC).mint(msg.sender, 1000 ether);
        IMintableBurnableERC20(SUSD).mint(msg.sender, 1e9 ether);
        IDegenBox(DEGEN_BOX).deposit(IMintableBurnableERC20(SUSD), msg.sender, SBTC_MARKET, 1e9 ether, 0);
    }
}
