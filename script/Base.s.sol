// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { Script } from "forge-std/Script.sol";

abstract contract BaseScript is Script {
    address internal broadcaster;
    uint256 internal nonce;
    uint256 internal gasPrice;

    constructor() {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        broadcaster = vm.addr(deployerPrivateKey);
        gasPrice = vm.envOr("GAS_PRICE", uint256(5 gwei));
        nonce = vm.getNonce(broadcaster);
    }

    modifier broadcast() {
        vm.deal(broadcaster, broadcaster.balance);
        vm.setNonce(broadcaster, uint64(nonce));
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
        nonce++;
    }
}
