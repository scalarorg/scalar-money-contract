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

    // Market configuration constants
    uint64 constant INTEREST_PER_SECOND = uint64((uint256(600) * 316_880_878) / 100);
    uint256 constant LIQUIDATION_MULTIPLIER = uint256(600) * 1e1 + 1e5;
    uint256 constant COLLATERIZATION_RATE = uint256(8000) * 1e1;
    uint256 constant BORROW_OPENING_FEE = uint256(50) * 1e1;

    // Deployed contract addresses
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
        require(!deployed, "Already deployed");
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
        require(address(stableCoin) == address(0), "Tokens already deployed");

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
        require(address(degenBox) == address(0), "DegenBox already deployed");
        require(address(stableCoin) != address(0), "Tokens must be deployed first");

        // Deploy DegenBox
        degenBox = new DegenBox(IERC20(address(weth)));

        // Deploy Master CauldronV4
        masterCauldron = new CauldronV4(IBentoBoxV1(address(degenBox)), IERC20(address(stableCoin)), msg.sender);

        // Whitelist master contract
        degenBox.whitelistMasterContract(address(masterCauldron), true);

        emit DegenBoxDeployed(address(degenBox), address(masterCauldron));
    }

    function deployOracle() internal {
        require(address(oracle) == address(0), "Oracle already deployed");

        // Deploy FixedPriceOracle
        oracle = new FixedPriceOracle("sBTC/sUSD", 100_000 ether, 18);

        // Deploy ProxyOracle
        oracleProxy = new ProxyOracle();
        oracleProxy.changeOracleImplementation(oracle);

        emit OracleDeployed(address(oracle), address(oracleProxy), "sBTC/sUSD Fixed Price Oracle");
    }

    function deployCauldronFactory() internal {
        require(address(cauldronFactory) == address(0), "CauldronFactory already deployed");
        require(address(masterCauldron) != address(0), "Master cauldron must be deployed first");

        cauldronFactory = new CauldronFactory(address(masterCauldron));
        emit CauldronFactoryDeployed(address(cauldronFactory), address(masterCauldron));
    }

    function deploySBTCMarket() internal {
        require(sBTCMarket == address(0), "sBTC market already deployed");
        require(address(cauldronFactory) != address(0), "CauldronFactory must be deployed first");
        require(address(oracleProxy) != address(0), "Oracle must be deployed first");

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
        require(address(degenBox) != address(0), "DegenBox must be deployed first");
        require(address(stableCoin) != address(0), "Tokens must be deployed first");

        stableCoin.approve(address(degenBox), type(uint256).max);
        sbtc.approve(address(degenBox), type(uint256).max);
        weth.approve(address(degenBox), type(uint256).max);
    }

    function deployMarketLens() internal {
        require(address(marketLens) == address(0), "MarketLens already deployed");

        marketLens = new MarketLens();
        emit MarketLensDeployed(address(marketLens));
    }
}
