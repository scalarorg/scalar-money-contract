// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// import { BaseTest } from "./BaseTest.sol";
// import { IBentoBoxV1 } from "@abracadabra/interfaces/IBentoBoxV1.sol";
// import { CauldronV4 } from "@abracadabra/cauldrons/CauldronV4.sol";
// import { ISwapperV2 } from "@abracadabra/interfaces/ISwapperV2.sol";
// import { IERC20 } from "@BoringSolidity/ERC20.sol";
// import { ERC20 } from "../src/tokens/ERC20.sol";
// import { RebaseLibrary, Rebase } from "@BoringSolidity/libraries/BoringRebase.sol";
// import { BoringMath, BoringMath128 } from "@BoringSolidity/libraries/BoringMath.sol";
// import { Vault } from "../src/cauldron/Vault.sol";

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

//     function liquidate(
//         address[] memory users,
//         uint256[] memory maxBorrowParts,
//         address to,
//         ISwapperV2 swapper,
//         bytes memory swapperData
//     )
//         external;

//     function userBorrowPart(address user) external view returns (uint256);

//     function maxBorrowPartToLiquidate(address user, uint256 maxBorrowPart) external view returns (uint256);
// }

// contract LiquidateTest is BaseTest {
//     function setUp() public override {
//         fork("sepolia");
//         super.setUp();
//         address SCALAR_WHALE = createUser("scalarWhale", address(0x11), 100_000 ether);

//         (
//             masterContract,
//             orderAgent,
//             gmETHDeployment,
//             ,
//             gmBTCDeployment,
//             ,
//             gmARBDeployment,
//             gmSOLDeployment,
//             gmLINKDeployment
//         ) = script.deploy();

//         box = IBentoBoxV1(toolkit.getAddress(block.chainid, "degenBox"));
//         mim = toolkit.getAddress(block.chainid, "mim");
//         gmBTC = toolkit.getAddress(block.chainid, "gmx.v2.gmBTC");
//         gmETH = toolkit.getAddress(block.chainid, "gmx.v2.gmETH");
//         weth = toolkit.getAddress(block.chainid, "weth");
//         gmARB = toolkit.getAddress(block.chainid, "gmx.v2.gmARB");
//         gmSOL = toolkit.getAddress(block.chainid, "gmx.v2.gmSOL");
//         gmLINK = toolkit.getAddress(block.chainid, "gmx.v2.gmLINK");
//         router = IGmxV2ExchangeRouter(toolkit.getAddress(block.chainid, "gmx.v2.exchangeRouter"));
//         usdc = toolkit.getAddress(block.chainid, "usdc");
//         exchange = new ExchangeRouterMock(address(0), address(0));

//         // Alice just made it
//         deal(usdc, alice, 100_000e6);
//         pushPrank(GM_BTC_WHALE);
//         gmBTC.safeTransfer(alice, 100_000 ether);
//         popPrank();
//         pushPrank(GM_ETH_WHALE);
//         gmETH.safeTransfer(alice, 100_000 ether);
//         popPrank();
//         pushPrank(GM_ARB_WHALE);
//         gmARB.safeTransfer(alice, 100_000 ether);
//         popPrank();
//         pushPrank(GM_SOL_WHALE);
//         gmSOL.safeTransfer(alice, 100_000 ether);
//         popPrank();
//         pushPrank(GM_LINK_WHALE);
//         gmLINK.safeTransfer(alice, 100_000 ether);
//         popPrank();

//         // put 1m mim inside the cauldrons
//         pushPrank(MIM_WHALE);
//         mim.safeTransfer(address(box), 5_000_000e18);
//         popPrank();

//         box.deposit(IERC20(mim), address(box), address(gmETHDeployment.cauldron), 1_000_000e18, 0);
//         box.deposit(IERC20(mim), address(box), address(gmBTCDeployment.cauldron), 1_000_000e18, 0);
//         box.deposit(IERC20(mim), address(box), address(gmARBDeployment.cauldron), 1_000_000e18, 0);
//         box.deposit(IERC20(mim), address(box), address(gmSOLDeployment.cauldron), 1_000_000e18, 0);
//         box.deposit(IERC20(mim), address(box), address(gmLINKDeployment.cauldron), 1_000_000e18, 0);

//         pushPrank(box.owner());
//         box.whitelistMasterContract(masterContract, true);
//         popPrank();
//     }
// }
