// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ICauldronV4 } from "@abracadabra/interfaces/ICauldronV4.sol";
import { CauldronV4 } from "@abracadabra/cauldrons/CauldronV4.sol";
import { MarketLens } from "@abracadabra/lenses/MarketLens.sol";
import { VaultTestLib } from "./VaultTestLib.sol";
import { console2 } from "forge-std/console2.sol";

// Import your BaseTest with the shared deployment logic
import "./BaseTest.sol"; // Adjust path as needed

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

contract DeployTest is BaseTest {
    address public _deployer;

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

    function testAddCollateralAndBorrow() public {
        pushPrank(alice);
        uint256 amountBefore = deployment.stableCoin.balanceOf(alice);
        uint256 collateralAmount = 1 ether; // 1 sBTC
        uint8 percentBorrow = 50;
        uint256 exchangeRate = deployment.marketLens.getOracleExchangeRate(ICauldronV4(address(deployment.vault))); // usd/sbtc
        uint256 borrowAmount = (collateralAmount * percentBorrow) / (100 * exchangeRate);

        // Create the position using the helper
        VaultTestLib.depositAndBorrow(
            IBentoBoxV1(address(deployment.degenBox)),
            ICauldronV4(address(deployment.vault)),
            address(deployment.masterContract),
            IERC20(address(deployment.sbtc)),
            alice,
            collateralAmount,
            percentBorrow
        );

        uint256 amountAfter = deployment.stableCoin.balanceOf(alice);
        console2.log("amountBefore:", amountBefore);
        console2.log("amountAfter:", amountAfter);
        console2.log("borrowAmount:", borrowAmount);

        // Assertions
        assertEq(amountAfter - amountBefore, borrowAmount * 1e18, "User should have received borrowed sUSD");
        popPrank();
    }

    function testDeployment() public {
        // Check that contracts are deployed and initialized
        assert(address(deployment.stableCoin) != address(0));
        assert(address(deployment.sbtc) != address(0));
        assert(address(deployment.weth) != address(0));
        assert(address(deployment.degenBox) != address(0));
        assert(address(deployment.masterContract) != address(0));
        assert(address(deployment.oracleProxy) != address(0));
        assert(address(deployment.vault) != address(0));
        assert(address(deployment.marketLens) != address(0));

        // Check oracle configuration
        if (address(CauldronV4(deployment.vault).oracle()) != address(deployment.oracleProxy)) {
            console2.log("CauldronV4 oracle:", address(CauldronV4(deployment.vault).oracle()));
            console2.log("ProxyOracle:", address(deployment.oracleProxy));
        }

        // Check exchange rates
        (, uint256 oracleRate) = deployment.oracleProxy.get("");
        console2.log("Oracle rate:", oracleRate);
        console2.log("Cauldron exchange rate:", CauldronV4(deployment.vault).exchangeRate());

        MarketLens.MarketInfo memory marketInfo =
            deployment.marketLens.getMarketInfoCauldronV3(ICauldronV3(deployment.vault));
        console2.log("Market oracle exchange rate:", marketInfo.oracleExchangeRate);
        console2.log("Market collateral price:", marketInfo.collateralPrice);
    }
}
