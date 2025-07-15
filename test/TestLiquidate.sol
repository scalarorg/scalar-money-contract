// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";
import { DegenBox } from "@abracadabra/DegenBox.sol";
import { IBentoBoxV1 } from "@abracadabra/interfaces/IBentoBoxV1.sol";
import { CauldronV4 } from "@abracadabra/cauldrons/CauldronV4.sol";
import { FixedPriceOracle } from "@abracadabra/oracles/FixedPriceOracle.sol";
import { ProxyOracle } from "@abracadabra/oracles/ProxyOracle.sol";
import { MarketLens } from "@abracadabra/lenses/MarketLens.sol";
import { ICauldronV3 } from "@abracadabra/interfaces/ICauldronV3.sol";
import { ISwapperV2 } from "@abracadabra/interfaces/ISwapperV2.sol";
import { IERC20 } from "@BoringSolidity/ERC20.sol";
import { StableCoin } from "../src/tokens/StableCoin.sol";
import { ERC20 } from "../src/tokens/ERC20.sol";
import { WETH } from "../src/tokens/WETH.sol";
import { CauldronFactory } from "../src/cauldron/CauldronFactory.sol";
import { console2 } from "forge-std/console2.sol";

import { RebaseLibrary, Rebase } from "@BoringSolidity/libraries/BoringRebase.sol";
import { BoringMath, BoringMath128 } from "@BoringSolidity/libraries/BoringMath.sol";

// Debug version of CauldronV4 with extensive logging
contract DebugCauldronV4 is CauldronV4 {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;

    constructor(
        IBentoBoxV1 bentoBox_,
        IERC20 magicInternetMoney_
    )
        CauldronV4(bentoBox_, magicInternetMoney_, msg.sender)
    { }

    function liquidate(
        address[] memory users,
        uint256[] memory maxBorrowParts,
        address to,
        ISwapperV2 swapper,
        bytes memory swapperData
    )
        public
        override
    {
        console2.log("=== LIQUIDATE FUNCTION START ===");
        console2.log("Caller (msg.sender):", msg.sender);
        console2.log("Liquidator (to):", to);
        console2.log("Number of users to liquidate:", users.length);
        console2.log("Swapper address:", address(swapper));
        console2.log("SwapperData length:", swapperData.length);

        // Log current exchange rate
        console2.log("Current exchangeRate:", exchangeRate);

        // Log each user's state before liquidation
        for (uint256 i = 0; i < users.length; i++) {
            // console2.log("--User", i, ":", users[i], "---");
            console2.log("MaxBorrowParts[%d]:", i, maxBorrowParts[i]);
            console2.log("Current userBorrowPart:", userBorrowPart[users[i]]);
            console2.log("Current userCollateralShare:", userCollateralShare[users[i]]);

            // Check if user is solvent
            bool solvent = _isSolvent(users[i], exchangeRate);
            console2.log("Is user solvent?", solvent);

            if (!solvent) {
                console2.log("User is INSOLVENT - will be liquidated");
            } else {
                console2.log("User is SOLVENT - will be skipped");
            }
        }

        // Log global state
        console2.log("Total collateral share:", totalCollateralShare);
        console2.log("Total borrow elastic:", totalBorrow.elastic);
        console2.log("Total borrow base:", totalBorrow.base);

        console2.log("=== CALLING ORIGINAL LIQUIDATE ===");

        // Call the original liquidate function
        super.liquidate(users, maxBorrowParts, to, swapper, swapperData);

        console2.log("=== LIQUIDATE FUNCTION END ===");
    }

    // Override _isSolvent to add logging
    function _isSolvent(address user, uint256 _exchangeRate) internal view override returns (bool) {
        console2.log("Checking solvency for user:", user);
        console2.log("Exchange rate used:", _exchangeRate);

        uint256 borrowPart = userBorrowPart[user];
        console2.log("User borrow part:", borrowPart);

        if (borrowPart == 0) {
            console2.log("No borrow - user is solvent");
            return true;
        }

        uint256 collateralShare = userCollateralShare[user];
        console2.log("User collateral share:", collateralShare);

        if (collateralShare == 0) {
            console2.log("No collateral but has debt - user is insolvent");
            return false;
        }

        // Calculate collateral value
        uint256 collateralValue = bentoBox.toAmount(
            collateral,
            collateralShare.mul(EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION).mul(COLLATERIZATION_RATE),
            false
        );
        console2.log("Collateral value (adjusted):", collateralValue);

        // Calculate debt value
        uint256 debtValue = borrowPart.mul(totalBorrow.elastic).mul(_exchangeRate) / totalBorrow.base;
        console2.log("Debt value:", debtValue);

        bool isSolvent = collateralValue >= debtValue;
        console2.log("Collateral >= Debt?", isSolvent);

        return isSolvent;
    }
}

interface ICauldronV4 {
    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    )
        external
        payable
        returns (uint256 value1, uint256 value2);

    function liquidate(
        address[] memory users,
        uint256[] memory maxBorrowParts,
        address to,
        ISwapperV2 swapper,
        bytes memory swapperData
    )
        external;
}

contract LiquidateTest is Test {
    address public USER;
    ICauldronV4 public cauldron;

    address constant CAULDRON_ADDRESS = 0xcE13BFeF6055e4Ef919211702825BBB338284758;

    function setUp() public {
        vm.createSelectFork("sepolia");

        uint256 private_key = vm.envUint("PRIVATE_KEY");
        USER = vm.addr(private_key);

        console2.log("Setting up test...");
        console2.log("User address:", USER);
        console2.log("Original cauldron address:", CAULDRON_ADDRESS);

        // Replace the contract at the deployed address with debug version
        replaceWithDebugVersion();

        cauldron = ICauldronV4(CAULDRON_ADDRESS);
        console2.log("Debug cauldron deployed successfully");

        vm.startPrank(USER);
        vm.stopPrank();
    }

    function replaceWithDebugVersion() internal {
        console2.log("Replacing contract with debug version...");

        // Get the original contract to read its constructor parameters
        CauldronV4 originalCauldron = CauldronV4(CAULDRON_ADDRESS);

        try originalCauldron.bentoBox() returns (IBentoBoxV1 bentoBox) {
            try originalCauldron.magicInternetMoney() returns (IERC20 mim) {
                console2.log("BentoBox:", address(bentoBox));
                console2.log("MIM:", address(mim));

                // Deploy debug version to get bytecode
                DebugCauldronV4 debugTemplate = new DebugCauldronV4(bentoBox, mim);
                console2.log("Debug template deployed at:", address(debugTemplate));

                // Replace bytecode at original address
                vm.etch(CAULDRON_ADDRESS, address(debugTemplate).code);
                console2.log("Bytecode replaced successfully");
            } catch {
                console2.log("Failed to get MIM address");
                revert("Failed to get MIM");
            }
        } catch {
            console2.log("Failed to get BentoBox address");
            revert("Failed to get BentoBox");
        }
    }

    function testLiquidate() public {
        console2.log("=== STARTING LIQUIDATION TEST ===");

        vm.startPrank(USER);
        uint256 ethBalance = USER.balance;
        console2.log("ETH Balance before liquidation:", ethBalance);

        address[] memory users = new address[](1);
        users[0] = USER;
        uint256[] memory maxBorrowParts = new uint256[](1);
        maxBorrowParts[0] = 148_740_000_000_000_000_000_000;

        console2.log("About to call liquidate with:");
        console2.log("User to liquidate:", users[0]);
        console2.log("Max borrow parts:", maxBorrowParts[0]);
        console2.log("Liquidator:", USER);

        // This will now show extensive debug output
        cauldron.liquidate(users, maxBorrowParts, USER, ISwapperV2(address(0)), new bytes(0));

        console2.log("=== LIQUIDATION TEST COMPLETE ===");
        vm.stopPrank();
    }
}
