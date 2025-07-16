// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// import { Test } from "forge-std/Test.sol";
// import { DegenBox } from "@abracadabra/DegenBox.sol";
// import { IBentoBoxV1 } from "@abracadabra/interfaces/IBentoBoxV1.sol";
// import { CauldronV4 } from "@abracadabra/cauldrons/CauldronV4.sol";
// import { FixedPriceOracle } from "@abracadabra/oracles/FixedPriceOracle.sol";
// import { ProxyOracle } from "@abracadabra/oracles/ProxyOracle.sol";
// import { MarketLens } from "@abracadabra/lenses/MarketLens.sol";
// import { ICauldronV3 } from "@abracadabra/interfaces/ICauldronV3.sol";
// import { IERC20 } from "@BoringSolidity/ERC20.sol";
// import { StableCoin } from "../src/tokens/StableCoin.sol";
// import { ERC20 } from "../src/tokens/ERC20.sol";
// import { WETH } from "../src/tokens/WETH.sol";
// import { CauldronFactory } from "../src/cauldron/CauldronFactory.sol";
// import { console2 } from "forge-std/console2.sol";

// interface ICauldronV4 {
//     function cook(
//         uint8[] calldata actions,
//         uint256[] calldata values,
//         bytes[] calldata datas
//     )
//         external
//         payable
//         returns (uint256 value1, uint256 value2);
// }

// contract DeployTest is Test {
//     StableCoin public stableCoin;
//     ERC20 public sbtc;
//     WETH public weth;
//     DegenBox public degenBox;
//     CauldronV4 public masterCauldron;
//     FixedPriceOracle public oracle;
//     ProxyOracle public oracleProxy;
//     CauldronFactory public cauldronFactory;
//     address public sBTCMarket;
//     MarketLens public marketLens;

//     // Market configuration constants
//     uint64 public constant INTEREST_PER_SECOND = uint64((uint256(600) * 316_880_878) / 100);
//     uint256 public constant LIQUIDATION_MULTIPLIER = uint256(600) * 1e1 + 1e5;
//     uint256 public constant COLLATERIZATION_RATE = uint256(8000) * 1e1;
//     uint256 public constant BORROW_OPENING_FEE = uint256(50) * 1e1;

//     address public USER;

//     function setUp() public {
//         uint256 privtekey = vm.envUint("PRIVATE_KEY");
//         USER = vm.addr(privtekey);

//         console2.log("USER", USER);

//         vm.startPrank(USER);

//         // 1. Deploy tokens
//         stableCoin = new StableCoin("ScalarUSD", "sUSD", 18);
//         sbtc = new ERC20("sBTC", "sBTC", 18);
//         weth = new WETH();

//         // 2. Deploy DegenBox and master cauldron
//         degenBox = new DegenBox(IERC20(address(weth)));
//         masterCauldron = new CauldronV4(IBentoBoxV1(address(degenBox)), IERC20(address(stableCoin)), USER);
//         degenBox.whitelistMasterContract(address(masterCauldron), true);

//         // 3. Deploy Oracle
//         oracle = new FixedPriceOracle("sBTC/sUSD", 1e13, 18);
//         oracleProxy = new ProxyOracle();
//         oracleProxy.changeOracleImplementation(oracle);

//         // 4. Deploy CauldronFactory
//         cauldronFactory = new CauldronFactory(address(masterCauldron), address(degenBox));

//         // 5. Deploy sBTC market
//         bytes memory oracleData = "";
//         bytes memory initData = abi.encode(
//             address(sbtc),
//             address(oracleProxy),
//             oracleData,
//             INTEREST_PER_SECOND,
//             LIQUIDATION_MULTIPLIER,
//             COLLATERIZATION_RATE,
//             BORROW_OPENING_FEE
//         );

//         sBTCMarket = cauldronFactory.createCauldron(initData);

//         // 6. Approve tokens for DegenBox
//         stableCoin.approve(address(degenBox), type(uint256).max);
//         sbtc.approve(address(degenBox), type(uint256).max);
//         weth.approve(address(degenBox), type(uint256).max);

//         // 7. Deploy MarketLens
//         marketLens = new MarketLens();

//         // Log all of contract addresses
//         console2.log("stableCoin: ", address(stableCoin));
//         console2.log("sbtc: ", address(sbtc));
//         console2.log("weth: ", address(weth));
//         console2.log("degenBox: ", address(degenBox));
//         console2.log("masterCauldron: ", address(masterCauldron));
//         console2.log("oracle: ", address(oracle));
//         console2.log("oracleProxy: ", address(oracleProxy));
//         console2.log("cauldronFactory: ", address(cauldronFactory));
//         console2.log("sBTCMarket: ", sBTCMarket);
//         console2.log("marketLens: ", address(marketLens));

//         vm.stopPrank();
//     }

//     function testAddCollateralAndBorrow() public {
//         // Whitelist the deployed cauldron instance in DegenBox (as deployer/owner)
//         // Approve tokens for DegenBox and master contract for the user
//         vm.startPrank(USER);

//         sbtc.mint(USER, 1000 ether);
//         stableCoin.mint(USER, 1e9 ether);
//         degenBox.deposit(IERC20(address(stableCoin)), USER, sBTCMarket, 1e9 ether, 0);
//         degenBox.setMasterContractApproval(USER, address(masterCauldron), true, 0, 0x0, 0x0);

//         // Mint tokens to USER
//         uint256 collateralAmount = 1 ether; // 1 sBTC (18 decimals)
//         uint256 borrowAmount = 777 ether; // 1 sUSD (18 decimals)

//         // // Prepare cook actions
//         uint8[] memory actions = new uint8[](3);
//         actions[0] = 20; // ACTION_BENTO_DEPOSIT
//         actions[1] = 10; // ACTION_ADD_COLLATERAL
//         actions[2] = 5; // ACTION_BORROW

//         uint256[] memory values = new uint256[](3);
//         values[0] = 0;
//         values[1] = 0;
//         values[2] = 0;

//         bytes[] memory datas = new bytes[](3);

//         // 1. ACTION_BENTO_DEPOSIT: Deposit collateral to market
//         uint256 collateralShare = degenBox.toShare(IERC20(address(sbtc)), collateralAmount, false);
//         datas[0] = abi.encode(IERC20(address(sbtc)), sBTCMarket, int256(collateralAmount), int256(collateralShare));

//         // 2. ACTION_ADD_COLLATERAL: Add collateral to user's position
//         datas[1] = abi.encode(int256(collateralShare), USER, true); // skim = true

//         // 3. ACTION_BORROW: Borrow sUSD
//         datas[2] = abi.encode(int256(borrowAmount), USER);

//         // Execute cook as USER
//         ICauldronV4(sBTCMarket).cook(actions, values, datas);

//         // Assertions
//         assertEq(stableCoin.balanceOf(USER), 777 ether, "User should have received borrowed sUSD");
//         vm.stopPrank();
//     }

//     function testDeployment() public {
//         // Check that contracts are deployed and initialized
//         assert(address(stableCoin) != address(0));
//         assert(address(sbtc) != address(0));
//         assert(address(weth) != address(0));
//         assert(address(degenBox) != address(0));
//         assert(address(masterCauldron) != address(0));
//         assert(address(oracle) != address(0));
//         assert(address(oracleProxy) != address(0));
//         assert(address(cauldronFactory) != address(0));
//         assert(address(sBTCMarket) != address(0));
//         assert(address(marketLens) != address(0));

//         // Check that the cauldron market is initialized with the correct oracle
//         // assertEq(CauldronV4(sBTCMarket).oracle(), address(oracleProxy));
//         if (address(CauldronV4(sBTCMarket).oracle()) != address(oracleProxy)) {
//             console2.log("CauldronV4(sBTCMarket).oracle()", address(CauldronV4(sBTCMarket).oracle()));
//             console2.log("address(oracleProxy)", address(oracleProxy));
//         }
//         // Check that the exchange rate is set (should match the oracle)
//         (, uint256 oracleRate) = oracleProxy.get("");
//         // assertEq(CauldronV4(sBTCMarket).exchangeRate(), oracleRate);
//         console2.log("oracleRate", oracleRate);
//         console2.log("CauldronV4(sBTCMarket).exchangeRate()", CauldronV4(sBTCMarket).exchangeRate());
//         MarketLens.MarketInfo memory marketInfo = marketLens.getMarketInfoCauldronV3(ICauldronV3(sBTCMarket));
//         console2.log("marketInfo.oracleExchangeRate", marketInfo.oracleExchangeRate);
//         console2.log("marketInfo.collateralPrice", marketInfo.collateralPrice);
//     }

//     function testSetMasterContractApproval() public {
//         uint8[] memory actions = new uint8[](1);
//         actions[0] = 24;
//         uint256[] memory values = new uint256[](1);
//         values[0] = 0;

//         // bytes32 digest = keccak256(
//         //         abi.encodePacked(
//         //             EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
//         //             DOMAIN_SEPARATOR(),
//         //             keccak256(
//         //                 abi.encode(
//         //                     APPROVAL_SIGNATURE_HASH,
//         //                     approved
//         //                         ? keccak256("Give FULL access to funds in (and approved to) BentoBox?")
//         //                         : keccak256("Revoke access to BentoBox?"),
//         //                     user,
//         //                     masterContract,
//         //                     approved,
//         //                     nonces[user]++
//         //                 )
//         //             )
//         //         )
//         //     );
//         //     address recoveredAddress = ecrecover(digest, v, r, s);
//         //     require(recoveredAddress == user, "MasterCMgr: Invalid Signature");

//         bytes[] memory datas = new bytes[](1);
//         datas[0] =
//             hex"000000000000000000000000aa31349a2ef4a37dc4dd742e3b0e32182f524a6a00000000000000000000000071a55104d585d31be65cc56fe1eee474a8c1a7490000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000001c59b3233cce47e0276183a80e00eb0de94a8d7472f036b1f1722147ba6e2804b13f5d1a9ced13ad4549fa5296bb7bf3776199fbd741bd7d467a330f11e589df7d";

//         (address user, address _masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) =
//             abi.decode(datas[0], (address, address, bool, uint8, bytes32, bytes32));

//         console2.log("user", user);
//         console2.log("_masterContract", _masterContract);
//         console2.log("approved", approved);
//         console2.log("v", v);
//         console2.logBytes32(r);
//         console2.logBytes32(s);
//         vm.startPrank(USER);
//         ICauldronV4(sBTCMarket).cook(actions, values, datas);
//         vm.stopPrank();
//     }

//     function testCook() public {
//         uint8[] memory actions = new uint8[](5);
//         actions[0] = 24;
//         actions[1] = 5;
//         actions[2] = 21;
//         actions[3] = 20;
//         actions[4] = 10;

//         uint256[] memory values = new uint256[](5);
//         values[0] = 0;
//         values[1] = 0;
//         values[2] = 0;
//         values[3] = 0;
//         values[4] = 0;

//         bytes[] memory datas = new bytes[](5);
//         datas[0] =
//             hex"000000000000000000000000aa31349a2ef4a37dc4dd742e3b0e32182f524a6a00000000000000000000000071a55104d585d31be65cc56fe1eee474a8c1a7490000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000001c59b3233cce47e0276183a80e00eb0de94a8d7472f036b1f1722147ba6e2804b13f5d1a9ced13ad4549fa5296bb7bf3776199fbd741bd7d467a330f11e589df7d";

//         datas[1] =
//             hex"00000000000000000000000000000000000000000000003635c9adc5dea00000000000000000000000000000aa31349a2ef4a37dc4dd742e3b0e32182f524a6a";

//         datas[2] =
//             hex"000000000000000000000000124c4a03c08601a0625bb5b543e58b2a61fce770000000000000000000000000aa31349a2ef4a37dc4dd742e3b0e32182f524a6a0000000000000000000000000000000000000000000000000000000000000000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe";

//         datas[3] =
//             hex"0000000000000000000000003cbb62d23120918019037b51a1e513fdaaddde3f000000000000000000000000962dbc8209eb083ed71c38cf4d7482c7c947cf140000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000000000000000000000000000000000000000000000";

//         datas[4] =
//             hex"fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe000000000000000000000000aa31349a2ef4a37dc4dd742e3b0e32182f524a6a0000000000000000000000000000000000000000000000000000000000000001";

//         vm.startPrank(USER);
//         ICauldronV4(sBTCMarket).cook(actions, values, datas);
//         vm.stopPrank();

//         console2.log(
//             "CauldronV4(sBTCMarket).userCollateralShare(USER)", CauldronV4(sBTCMarket).userCollateralShare(USER)
//         );
//         console2.log("CauldronV4(sBTCMarket).userBorrowPart(USER)", CauldronV4(sBTCMarket).userBorrowPart(USER));
//     }
// }
