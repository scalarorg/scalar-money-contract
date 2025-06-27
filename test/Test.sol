// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { Vm } from "forge-std/src/Vm.sol";

// import { console2 } from "forge-std/src/console2.sol";

contract ScalarGatewayTest is Test {
    function setUp() public {
        // Fork mainnet
        vm.createSelectFork("mainnet");

        owner = makeAddr("owner");
    }
}
