// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ProxyOracle } from "@abracadabra/oracles/ProxyOracle.sol";
import { FixedPriceOracle } from "@abracadabra/oracles/FixedPriceOracle.sol";
import { BaseScript } from "./Base.s.sol";

contract SetOracleScript is BaseScript {
    // address public constant PROXY_ORACLE = 0xc8D890dcA44d788101AED28bf9A47232ce37EeC9;

    address proxy_oracle = vm.envAddress("PROXY_ORACLE");

    function run() external broadcast {
        FixedPriceOracle oracle = new FixedPriceOracle("sBTC/sUSD", 5e12, 18);
        ProxyOracle(proxy_oracle).changeOracleImplementation(oracle);
    }
}
