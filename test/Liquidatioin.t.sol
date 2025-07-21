// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ICauldronV4 } from "@abracadabra/interfaces/ICauldronV4.sol";
import { CauldronV4 } from "@abracadabra/cauldrons/CauldronV4.sol";
import { MarketLens } from "@abracadabra/lenses/MarketLens.sol";
import { VaultTestLib } from "./VaultTestLib.sol";
import { console2 } from "forge-std/console2.sol";

import "./BaseTest.sol";

contract LiquidatioinTest is BaseTest {
    address public _deployer;

    uint256 public constant collateralAmount = 1 ether; // 1 sBTC
    uint8 public constant percentBorrow = 80;

    function setUp() public override {
        super.setUp();

        _deployer = createUser("deployer", address(0x777), 1000 ether);

        // Deploy the entire Scalar system
        deployment = deployScalarSystem(_deployer);

        // Prepare indeployScalarSystem
        prepareLiquidity(deployment);

        // Prepare the USER with tokens and approvals
        prepareUser(
            alice,
            deployment,
            1e9 ether, // stableCoin amount
            1000 ether, // sBTC amount
            100 ether // ETH amount
        );
    }

    function testLiquidation() public {
        pushPrank(alice);

        VaultTestLib.depositAndBorrow(
            IBentoBoxV1(address(deployment.degenBox)),
            ICauldronV4(address(deployment.vault)),
            address(deployment.masterContract),
            IERC20(address(deployment.sbtc)),
            alice,
            collateralAmount,
            percentBorrow
        );

        assertTrue(ICauldronV4(deployment.vault).isSolvent(alice), "alice is insolvent");
        uint256 userCollateralShare = ICauldronV4(deployment.vault).userCollateralShare(alice);
        uint256 amount = deployment.degenBox.toAmount(IERC20(address(deployment.sbtc)), userCollateralShare, true);
        assertEq(amount, collateralAmount, "user collateral is wrong");
        popPrank();
    }
}
