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

    function maxBorrowPartToLiquidate(address user, uint256 maxBorrowPart) public returns (uint256) {
        uint256 borrowPart;
        Rebase memory bentoBoxTotals = bentoBox.totals(collateral);
        uint256 availableBorrowPart = userBorrowPart[user];
        borrowPart = maxBorrowPart > availableBorrowPart ? availableBorrowPart : maxBorrowPart;

        (, uint256 _exchangeRate) = oracle.get(oracleData);

        uint256 borrowAmount = totalBorrow.toElastic(borrowPart, false);
        uint256 collateralShare = bentoBoxTotals.toBase(
            borrowAmount.mul(LIQUIDATION_MULTIPLIER).mul(_exchangeRate)
                / (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
            false
        );

        uint256 userCollateral = userCollateralShare[user];

        if (userCollateral >= collateralShare) {
            return borrowPart;
        }

        // Convert collateral share to base amount
        uint256 collateralAmount = bentoBoxTotals.toElastic(userCollateral, false);

        // Calculate max borrow amount based on collateral
        // collateralAmount * exchangeRate / liquidationMultiplier = maxBorrowAmount
        uint256 maxBorrowAmount = collateralAmount.mul(EXCHANGE_RATE_PRECISION).mul(LIQUIDATION_MULTIPLIER_PRECISION)
            / (_exchangeRate.mul(LIQUIDATION_MULTIPLIER));

        return totalBorrow.toBase(maxBorrowAmount, false);
    }
}
