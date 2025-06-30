// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { DegenBox } from "@abracadabra/DegenBox.sol";
import { IBentoBoxV1 } from "@abracadabra/interfaces/IBentoBoxV1.sol";
import { CauldronV4 } from "@abracadabra/cauldrons/CauldronV4.sol";
import { FixedPriceOracle } from "@abracadabra/oracles/FixedPriceOracle.sol";
import { ProxyOracle } from "@abracadabra/oracles/ProxyOracle.sol";
import { MarketLens } from "@abracadabra/lenses/MarketLens.sol";
import { IERC20 } from "@BoringSolidity/ERC20.sol";
import { BaseScript } from "./Base.s.sol";
import { StableCoin } from "../src/tokens/StableCoin.sol";
import { ERC20 } from "../src/tokens/ERC20.sol";
import { WETH } from "../src/tokens/WETH.sol";
import { CauldronFactory } from "../src/cauldron/CauldronFactory.sol";

contract ScalarSystemDeployScript is BaseScript {
    // Events for better deployment tracking
    event TokenDeployed(string name, address indexed token, string symbol, uint8 decimals);
    event DegenBoxDeployed(address indexed degenBox, address indexed masterCauldron);
    event OracleDeployed(address indexed oracle, address indexed proxy, string description);
    event CauldronFactoryDeployed(address indexed factory, address indexed masterContract);
    event MarketDeployed(address indexed market, address indexed collateral, address indexed oracle);
    event MarketLensDeployed(address indexed lens);

    error AlreadyDeployed();
    error NotDeployed();

    uint64 public constant INTEREST_PER_SECOND = uint64((uint256(600) * 316_880_878) / 100);
    uint256 public constant LIQUIDATION_MULTIPLIER = uint256(600) * 1e1 + 1e5;
    uint256 public constant COLLATERIZATION_RATE = uint256(8000) * 1e1;
    uint256 public constant BORROW_OPENING_FEE = uint256(50) * 1e1;

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

    // Deployment state tracking
    bool public deployed;

    modifier onlyOnce() {
        if (deployed) revert AlreadyDeployed();
        _;
        deployed = true;
    }

    function run()
        external
        broadcast
        returns (
            StableCoin,
            ERC20,
            WETH,
            DegenBox,
            CauldronV4,
            FixedPriceOracle,
            ProxyOracle,
            CauldronFactory,
            address,
            MarketLens
        )
    {
        // 1. Deploy tokens
        deployTokens();

        // 2. Deploy DegenBox and master cauldron
        deployDegenBoxAndMasterCauldron();

        // 3. Deploy Oracle
        deployOracle();

        // 4. Deploy CauldronFactory
        deployCauldronFactory();

        // 5. Deploy sBTC market
        deploySBTCMarket();

        // 6. Approve tokens for DegenBox
        approveTokensForDegenBox();

        // 7. Deploy MarketLens
        deployMarketLens();

        return (
            stableCoin,
            sbtc,
            weth,
            degenBox,
            masterCauldron,
            oracle,
            oracleProxy,
            cauldronFactory,
            sBTCMarket,
            marketLens
        );
    }

    function deployTokens() internal {
        if (address(stableCoin) != address(0)) revert AlreadyDeployed();

        // Deploy ScalarUSD
        stableCoin = new StableCoin("ScalarUSD", "sUSD", 18);
        emit TokenDeployed("ScalarUSD", address(stableCoin), "sUSD", 18);

        // Deploy sBTC
        sbtc = new ERC20("sBTC", "sBTC", 8);
        emit TokenDeployed("sBTC", address(sbtc), "sBTC", 8);

        // Deploy WETH
        weth = new WETH();
        emit TokenDeployed("WETH", address(weth), "WETH", 18);
    }

    function deployDegenBoxAndMasterCauldron() internal {
        if (address(degenBox) != address(0)) revert AlreadyDeployed();
        if (address(stableCoin) == address(0)) revert NotDeployed();

        // Deploy DegenBox
        degenBox = new DegenBox(IERC20(address(weth)));

        // Deploy Master CauldronV4
        masterCauldron = new CauldronV4(IBentoBoxV1(address(degenBox)), IERC20(address(stableCoin)), msg.sender);

        // Whitelist master contract
        degenBox.whitelistMasterContract(address(masterCauldron), true);

        emit DegenBoxDeployed(address(degenBox), address(masterCauldron));
    }

    function deployOracle() internal {
        if (address(oracle) != address(0)) revert AlreadyDeployed();

        // Deploy FixedPriceOracle: 1 USD = ? SBTC
        // 1 USD = 1/100K * 1e18 = 1e13
        oracle = new FixedPriceOracle("sBTC/sUSD", 1e13, 18);

        // Deploy ProxyOracle
        oracleProxy = new ProxyOracle();
        oracleProxy.changeOracleImplementation(oracle);

        emit OracleDeployed(address(oracle), address(oracleProxy), "sBTC/sUSD Fixed Price Oracle");
    }

    function deployCauldronFactory() internal {
        if (address(cauldronFactory) != address(0)) revert AlreadyDeployed();
        if (address(masterCauldron) == address(0)) revert NotDeployed();

        cauldronFactory = new CauldronFactory(address(masterCauldron));
        emit CauldronFactoryDeployed(address(cauldronFactory), address(masterCauldron));
    }

    function deploySBTCMarket() internal {
        if (sBTCMarket != address(0)) revert AlreadyDeployed();
        if (address(cauldronFactory) == address(0)) revert NotDeployed();
        if (address(oracleProxy) == address(0)) revert NotDeployed();

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

        emit MarketDeployed(sBTCMarket, address(sbtc), address(oracleProxy));
    }

    function approveTokensForDegenBox() internal {
        if (address(degenBox) == address(0)) revert NotDeployed();
        if (address(stableCoin) == address(0)) revert NotDeployed();

        stableCoin.approve(address(degenBox), type(uint256).max);
        sbtc.approve(address(degenBox), type(uint256).max);
        weth.approve(address(degenBox), type(uint256).max);
    }

    function deployMarketLens() internal {
        if (address(marketLens) != address(0)) revert AlreadyDeployed();

        marketLens = new MarketLens();
        emit MarketLensDeployed(address(marketLens));
    }
}
