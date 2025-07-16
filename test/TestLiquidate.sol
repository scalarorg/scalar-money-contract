// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";
import { IBentoBoxV1 } from "@abracadabra/interfaces/IBentoBoxV1.sol";
import { CauldronV4 } from "@abracadabra/cauldrons/CauldronV4.sol";
import { ISwapperV2 } from "@abracadabra/interfaces/ISwapperV2.sol";
import { IERC20 } from "@BoringSolidity/ERC20.sol";
import { ERC20 } from "../src/tokens/ERC20.sol";
import { RebaseLibrary, Rebase } from "@BoringSolidity/libraries/BoringRebase.sol";
import { BoringMath, BoringMath128 } from "@BoringSolidity/libraries/BoringMath.sol";
import { Vault } from "../src/cauldron/Vault.sol";

import { console2 } from "forge-std/console2.sol";

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

    function userBorrowPart(address user) external view returns (uint256);

    function maxBorrowPartToLiquidate(address user, uint256 maxBorrowPart) external view returns (uint256);
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
                Vault debugTemplate = new Vault(USER, address(bentoBox), address(mim));
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
        maxBorrowParts[0] = cauldron.userBorrowPart(USER);

        console2.log("About to call liquidate with:");
        console2.log("User to liquidate:", users[0]);
        console2.log("Max borrow parts:", maxBorrowParts[0]);
        console2.log("Liquidator:", USER);

        uint256 borrowAmountPart = cauldron.maxBorrowPartToLiquidate(USER, maxBorrowParts[0]);
        console2.log("cauldron.maxBorrowPartToLiquidate:", borrowAmountPart);
        maxBorrowParts[0] = borrowAmountPart;

        // This will now show extensive debug output
        cauldron.liquidate(users, maxBorrowParts, USER, ISwapperV2(address(0)), new bytes(0));

        console2.log("=== LIQUIDATION TEST COMPLETE ===");
        vm.stopPrank();
    }
}
