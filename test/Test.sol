// // SPDX-License-Identifier: UNLICENSED
// pragma solidity >=0.8.0 <0.9.0;

// import { Test } from "forge-std/Test.sol";
// import { Vm } from "forge-std/Vm.sol";

// import { console2 } from "forge-std/console2.sol";

// contract ScalarGatewayTest is Test {
//     function setUp() public { }

//     function testDecodeProvidedCreateCauldronInput() public {
//         console2.log("testDecodeProvidedCreateCauldronInput");

//         // Provided input data (after selector):
//         // Full calldata (with selector)
//         bytes memory fullData =
//             hex"b9989b4d00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000100000000000000000000000000a32e5903815476aff6e784f5644b1e0e3ee2081b000000000000000000000000d9139318aa0aebde732040ba04f4658cf0bc441f00000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000071534f940000000000000000000000000000000000000000000000000000000000019e10000000000000000000000000000000000000000000000000000000000001388000000000000000000000000000000000000000000000000000000000000001f40000000000000000000000000000000000000000000000000000000000000000";

//         // Remove the first 4 bytes (function selector)
//         bytes memory data = new bytes(fullData.length - 4);
//         for (uint256 i = 0; i < data.length; i++) {
//             data[i] = fullData[i + 4];
//         }

//         // The first 32 bytes is the offset to the bytes argument, so skip it
//         bytes memory inner = new bytes(data.length - 32);
//         for (uint256 i = 0; i < inner.length; i++) {
//             inner[i] = data[i + 32];
//         }

//         (
//             address collateral,
//             address oracle,
//             bytes memory oracleData,
//             uint64 interestPerSecond,
//             uint256 liquidationMultiplier,
//             uint256 collaterizationRate,
//             uint256 borrowOpeningFee
//         ) = abi.decode(inner, (address, address, bytes, uint64, uint256, uint256, uint256));

//         console2.logAddress(collateral);
//         // console2.log(oracle);
//         // console2.log(oracleData);
//         // console2.log(interestPerSecond);
//         // console2.log(liquidationMultiplier);
//         // console2.log(collaterizationRate);
//         // console2.log(borrowOpeningFee);
//     }
// }
