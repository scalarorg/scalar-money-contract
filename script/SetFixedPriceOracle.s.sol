// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { FixedPriceOracle } from "@abracadabra/oracles/FixedPriceOracle.sol";
import { IOracle } from "@abracadabra/interfaces/IOracle.sol";
import { ProxyOracle } from "@abracadabra/oracles/ProxyOracle.sol";
import { BaseScript } from "./Base.s.sol";

contract SetFixedPriceOracle is BaseScript {
    address proxy_oracle = 0xC36F55c1F2Be86Eb7cb911eA573bb105101760D1;

    function run() external broadcast {
        FixedPriceOracle oracle = new FixedPriceOracle("sBTC/sUSD", 5e12, 18);
        ProxyOracle(proxy_oracle).changeOracleImplementation(IOracle(oracle));
    }
}
