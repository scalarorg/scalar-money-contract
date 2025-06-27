// // SPDX-License-Identifier: UNLICENSED
// pragma solidity >=0.8.0;

// // import "./BaseScript.sol";
// // import "/tokens/ScalarCoin.sol";
// // import "/tokens/WETH.sol";
// // import "/tokens/sBTC.sol";
// // import "/DegenBox.sol";
// // import "/cauldrons/CauldronV4.sol";
// // import "/oracles/FixedPriceOracle.sol";
// // import "/oracles/ProxyOracle.sol";
// // import "/factories/CauldronFactory.sol";
// // import "/lenses/MarketLens.sol";

// import { BaseScript } from "./Base.s.sol";
// import { StableCoin } from "../src/tokens/StableCoin.sol";
// import { ERC20 } from "../src/tokens/ERC20.sol";
// import { WETH } from "../src/tokens/WETH.sol";
// import { DegenBox } from "@abracadabra/DegenBox.sol";
// import { CauldronV4 } from "@abracadabra/cauldrons/CauldronV4.sol";
// import { FixedPriceOracle } from "@abracadabra/oracles/FixedPriceOracle.sol";
// import { ProxyOracle } from "@abracadabra/oracles/ProxyOracle.sol";
// import { CauldronFactory } from "@abracadabra/contracts/factories/CauldronFactory.sol";
// import { MarketLens } from "@abracadabra/contracts/lenses/MarketLens.sol";

// contract ScalarSystemDeployScript is BaseScript {
//   function deploy() public {
//     vm.startBroadcast();

//     // 1. Deploy ScalarUSD
//     StableCoin token = new StableCoin("ScalarUSD", "sUSD", 18);

//     // 2. Deploy sBTC
//     ERC20 sbtc = new ERC20("sBTC", "sBTC", 8);

//     // 3. Deploy WETH
//     WETH weth = new WETH();

//     // 4. Deploy DegenBox
//     DegenBox degenBox = new DegenBox(address(weth));

//     // 5. Deploy CauldronV4
//     CauldronV4 cauldronV4 = new CauldronV4(address(degenBox), address(token));

//     // 6. Deploy FixedPriceOracle
//     FixedPriceOracle oracle = new FixedPriceOracle("sBTC/USD", 17471700000000, 8);

//     // 7. Deploy ProxyOracle and set implementation
//     ProxyOracle oracleProxy = new ProxyOracle();
//     oracleProxy.changeOracleImplementation(address(oracle));

//     // 8. Deploy CauldronFactory
//     CauldronFactory cauldronFactory = new CauldronFactory(address(cauldronV4));

//     // 9. Encode initData and clone CauldronV4 for sBTC market
//     bytes memory oracleData = "";
//     uint64 INTEREST_PER_SECOND = uint64((uint256(600) * 316880878) / 100);
//     uint256 LIQUIDATION_MULTIPLIER = uint256(600) * 1e1 + 1e5;
//     uint256 COLLATERIZATION_RATE = uint256(8000) * 1e1;
//     uint256 BORROW_OPENING_FEE = uint256(50) * 1e1;

//     bytes memory initData = abi.encode(
//       address(sbtc),
//       address(oracleProxy),
//       oracleData,
//       INTEREST_PER_SECOND,
//       LIQUIDATION_MULTIPLIER,
//       COLLATERIZATION_RATE,
//       BORROW_OPENING_FEE
//     );

//     address sBTCMarket = cauldronFactory.createCauldron(initData);

//     // 10. Whitelist master contract
//     degenBox.whitelistMasterContract(address(cauldronV4), true);

//     // 11. Approve tokens for DegenBox
//     token.approve(address(degenBox), type(uint256).max);
//     sbtc.approve(address(degenBox), type(uint256).max);
//     weth.approve(address(degenBox), type(uint256).max);

//     // 12. Mint tokens to deployer
//     sbtc.mint(msg.sender, 10_000 ether);
//     token.mint(msg.sender, 3_000_000 ether);

//     // 13. Deposit SCL tokens to the market
//     degenBox.deposit(address(token), msg.sender, sBTCMarket, 3_000_000 ether, 0);

//     // 14. Deploy MarketLens
//     MarketLens marketLens = new MarketLens();

//     vm.stopBroadcast();
//   }
// }
