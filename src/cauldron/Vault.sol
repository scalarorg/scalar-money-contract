// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { CauldronV4 } from "@abracadabra/cauldrons/CauldronV4.sol";
import { IBentoBoxV1 } from "@abracadabra/interfaces/IBentoBoxV1.sol";
import { IERC20 } from "@BoringSolidity/ERC20.sol";
import { BoringMath, BoringMath128 } from "@BoringSolidity/libraries/BoringMath.sol";
import { RebaseLibrary, Rebase } from "@BoringSolidity/libraries/BoringRebase.sol";
import { console2 } from "forge-std/console2.sol";

contract Vault is CauldronV4 {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;

    constructor(
        address owner,
        address bentoBox_,
        address magicInternetMoney_
    )
        CauldronV4(IBentoBoxV1(bentoBox_), IERC20(magicInternetMoney_), owner)
    { }

    // function maxBorrowPartToLiquidate(address user, uint256 maxBorrowPart) public returns (uint256) {
    //     // Update exchange rate and accrue interest first
    //     (, uint256 _exchangeRate) = updateExchangeRate();
    //     accrue();

    //     uint256 availableBorrowPart = userBorrowPart[user];
    //     uint256 userCollateral = userCollateralShare[user];

    //     console2.log("[maxBorrowPartToLiquidate] availableBorrowPart:", availableBorrowPart);
    //     console2.log("[maxBorrowPartToLiquidate] userCollateral:", userCollateral);
    //     console2.log("[maxBorrowPartToLiquidate] exchangeRate:", _exchangeRate);

    //     if (availableBorrowPart == 0 || userCollateral == 0) {
    //         return 0;
    //     }

    //     // Calculate the maximum borrow amount that can be liquidated based on available collateral
    //     // Formula: maxBorrowAmount = userCollateral * exchangeRate / liquidationMultiplier
    //     uint256 maxBorrowAmountFromCollateral =
    // userCollateral.mul(_exchangeRate).mul(LIQUIDATION_MULTIPLIER_PRECISION)
    //         / (LIQUIDATION_MULTIPLIER.mul(EXCHANGE_RATE_PRECISION));

    //     console2.log("[maxBorrowPartToLiquidate] maxBorrowAmountFromCollateral:", maxBorrowAmountFromCollateral);

    //     // Convert borrow amount to borrow part
    //     uint256 maxBorrowPartFromCollateral = totalBorrow.toBase(maxBorrowAmountFromCollateral, false);

    //     console2.log("[maxBorrowPartToLiquidate] maxBorrowPartFromCollateral:", maxBorrowPartFromCollateral);

    //     // Take the minimum of:
    //     // 1. Available borrow part
    //     // 2. Requested max borrow part
    //     // 3. Max borrow part that can be covered by collateral
    //     uint256 safeBorrowPart = availableBorrowPart;
    //     if (maxBorrowPart < safeBorrowPart) {
    //         safeBorrowPart = maxBorrowPart;
    //     }
    //     if (maxBorrowPartFromCollateral < safeBorrowPart) {
    //         safeBorrowPart = maxBorrowPartFromCollateral;
    //     }

    //     console2.log("[maxBorrowPartToLiquidate] final safeBorrowPart:", safeBorrowPart);

    //     // Verify this won't cause underflow by calculating required collateral
    //     if (safeBorrowPart > 0) {
    //         Rebase memory bentoBoxTotals = bentoBox.totals(collateral);
    //         uint256 borrowAmount = totalBorrow.toElastic(safeBorrowPart, false);
    //         uint256 requiredCollateralShare = bentoBoxTotals.toBase(
    //             borrowAmount.mul(LIQUIDATION_MULTIPLIER).mul(_exchangeRate)
    //                 / (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
    //             false
    //         );

    //         console2.log("[maxBorrowPartToLiquidate] borrowAmount:", borrowAmount);
    //         console2.log("[maxBorrowPartToLiquidate] requiredCollateralShare:", requiredCollateralShare);

    //         // If required collateral exceeds available, reduce the borrow part proportionally
    //         if (requiredCollateralShare > userCollateral) {
    //             // Calculate the ratio and reduce borrow part accordingly
    //             safeBorrowPart = safeBorrowPart.mul(userCollateral) / requiredCollateralShare;
    //             console2.log("[maxBorrowPartToLiquidate] reduced safeBorrowPart:", safeBorrowPart);
    //         }
    //     }

    //     return safeBorrowPart;
    // }
}
