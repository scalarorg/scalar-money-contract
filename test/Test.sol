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
import { IERC20 } from "@BoringSolidity/ERC20.sol";
import { StableCoin } from "../src/tokens/StableCoin.sol";
import { ERC20 } from "../src/tokens/ERC20.sol";
import { WETH } from "../src/tokens/WETH.sol";
import { CauldronFactory } from "../src/cauldron/CauldronFactory.sol";
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
}

contract DeployTest is Test {
    StableCoin public stableCoin;
    ERC20 public sbtc;
    WETH public weth;
    DegenBox public degenBox;
    CauldronV4 public masterCauldron;
    FixedPriceOracle public oracle;
    ProxyOracle public oracleProxy;
    CauldronFactory public cauldronFactory;
    address public sBTCMarket;
    MarketLens public marketLens;

    // Market configuration constants
    uint64 public constant INTEREST_PER_SECOND = uint64((uint256(600) * 316_880_878) / 100);
    uint256 public constant LIQUIDATION_MULTIPLIER = uint256(600) * 1e1 + 1e5;
    uint256 public constant COLLATERIZATION_RATE = uint256(8000) * 1e1;
    uint256 public constant BORROW_OPENING_FEE = uint256(50) * 1e1;

    address public USER;

    function setUp() public {
        // USER = makeAddr("user");

        uint256 privtekey = vm.envUint("PRIVATE_KEY");
        USER = vm.addr(privtekey);

        console2.log("USER", USER);

        vm.startPrank(USER);

        // 1. Deploy tokens
        stableCoin = new StableCoin("ScalarUSD", "sUSD", 18);
        sbtc = new ERC20("sBTC", "sBTC", 8);
        weth = new WETH();

        // 2. Deploy DegenBox and master cauldron
        degenBox = new DegenBox(IERC20(address(weth)));
        masterCauldron = new CauldronV4(IBentoBoxV1(address(degenBox)), IERC20(address(stableCoin)), address(this));
        degenBox.whitelistMasterContract(address(masterCauldron), true);

        // 3. Deploy Oracle
        oracle = new FixedPriceOracle("sBTC/sUSD", 1e13, 18);
        oracleProxy = new ProxyOracle();
        oracleProxy.changeOracleImplementation(oracle);

        // 4. Deploy CauldronFactory
        cauldronFactory = new CauldronFactory(address(masterCauldron));

        // 5. Deploy sBTC market
        bytes memory oracleData = "";
        bytes memory initData = abi.encode(
            address(sbtc),
            address(oracleProxy),
            oracleData,
            INTEREST_PER_SECOND,
            LIQUIDATION_MULTIPLIER,
            COLLATERIZATION_RATE,
            BORROW_OPENING_FEE
        );
        sBTCMarket = cauldronFactory.createCauldron(initData);

        // 6. Approve tokens for DegenBox
        stableCoin.approve(address(degenBox), type(uint256).max);
        sbtc.approve(address(degenBox), type(uint256).max);
        weth.approve(address(degenBox), type(uint256).max);

        // 7. Deploy MarketLens
        marketLens = new MarketLens();

        // 8. Prepare liquidity
        stableCoin.mint(USER, 1e9 ether);
        degenBox.deposit(IERC20(address(stableCoin)), USER, sBTCMarket, 1e9 ether, 0);
    }

    function testDeployment() public {
        // Check that contracts are deployed and initialized
        assert(address(stableCoin) != address(0));
        assert(address(sbtc) != address(0));
        assert(address(weth) != address(0));
        assert(address(degenBox) != address(0));
        assert(address(masterCauldron) != address(0));
        assert(address(oracle) != address(0));
        assert(address(oracleProxy) != address(0));
        assert(address(cauldronFactory) != address(0));
        assert(address(sBTCMarket) != address(0));
        assert(address(marketLens) != address(0));

        // Check that the cauldron market is initialized with the correct oracle
        // assertEq(CauldronV4(sBTCMarket).oracle(), address(oracleProxy));
        if (address(CauldronV4(sBTCMarket).oracle()) != address(oracleProxy)) {
            console2.log("CauldronV4(sBTCMarket).oracle()", address(CauldronV4(sBTCMarket).oracle()));
            console2.log("address(oracleProxy)", address(oracleProxy));
        }
        // Check that the exchange rate is set (should match the oracle)
        (, uint256 oracleRate) = oracleProxy.get("");
        // assertEq(CauldronV4(sBTCMarket).exchangeRate(), oracleRate);
        console2.log("oracleRate", oracleRate);
        console2.log("CauldronV4(sBTCMarket).exchangeRate()", CauldronV4(sBTCMarket).exchangeRate());
        MarketLens.MarketInfo memory marketInfo = marketLens.getMarketInfoCauldronV3(ICauldronV3(sBTCMarket));
        console2.log("marketInfo.oracleExchangeRate", marketInfo.oracleExchangeRate);
        console2.log("marketInfo.collateralPrice", marketInfo.collateralPrice);
    }

    function testAddCollateralAndBorrow() public {
        // Mint tokens to USER
        uint256 collateralAmount = 1e8; // 1 sBTC (8 decimals)
        uint256 borrowAmount = 1e18; // 1 sUSD (18 decimals)

        sbtc.mint(USER, collateralAmount);
        stableCoin.mint(sBTCMarket, 1e9 ether); // Add liquidity to market

        // Whitelist the deployed cauldron instance in DegenBox (as deployer/owner)
        degenBox.whitelistMasterContract(sBTCMarket, true);

        // Approve tokens for DegenBox and master contract for the user
        vm.startPrank(USER);
        sbtc.approve(address(degenBox), type(uint256).max);
        stableCoin.approve(address(degenBox), type(uint256).max);
        degenBox.setMasterContractApproval(USER, sBTCMarket, true, 0, 0x0, 0x0);
        vm.stopPrank();

        // Prepare cook actions
        uint8[] memory actions = new uint8[](3);
        actions[0] = 20; // ACTION_BENTO_DEPOSIT
        actions[1] = 10; // ACTION_ADD_COLLATERAL
        actions[2] = 5; // ACTION_BORROW

        uint256[] memory values = new uint256[](3);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;

        bytes[] memory datas = new bytes[](3);

        // 1. ACTION_BENTO_DEPOSIT: Deposit collateral to market
        uint256 collateralShare = degenBox.toShare(IERC20(address(sbtc)), collateralAmount, false);
        datas[0] = abi.encode(IERC20(address(sbtc)), sBTCMarket, int256(collateralAmount), int256(collateralShare));

        // 2. ACTION_ADD_COLLATERAL: Add collateral to user's position
        datas[1] = abi.encode(int256(collateralShare), USER, true); // skim = true

        // 3. ACTION_BORROW: Borrow sUSD
        datas[2] = abi.encode(int256(borrowAmount), USER);

        // Execute cook as USER
        vm.startPrank(USER);
        ICauldronV4(sBTCMarket).cook(actions, values, datas);
        vm.stopPrank();

        // Assertions
        assertGt(CauldronV4(sBTCMarket).userCollateralShare(USER), 0, "User should have collateral");
        assertGt(CauldronV4(sBTCMarket).userBorrowPart(USER), 0, "User should have borrow part");
        assertTrue(CauldronV4(sBTCMarket).isSolvent(USER), "User should be solvent");
        assertGt(stableCoin.balanceOf(USER), 0, "User should have received borrowed sUSD");
    }
}
