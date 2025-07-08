// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { IOracle } from "@abracadabra/interfaces/IOracle.sol";
import { ProxyOracle } from "@abracadabra/oracles/ProxyOracle.sol";
import { FixedPriceOracle } from "@abracadabra/oracles/FixedPriceOracle.sol";
import { BaseScript } from "./Base.s.sol";
import { ChainLinkOracleAdaptor } from "../src/oracles/ChainLinkOracleAdaptor.sol";

contract SetOracleScript is BaseScript {
    address proxy_oracle = 0xF5146e0F0D0d09cb681268bcDA78A79d0F9758fA;

    address constant chainLinkOracles = 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43;

    function run() external broadcast {
        ChainLinkOracleAdaptor oracle = new ChainLinkOracleAdaptor(chainLinkOracles, 18, "sBTC/sUSD", "sBTC/sUSD");
        ProxyOracle(proxy_oracle).changeOracleImplementation(IOracle(oracle));
    }
}
