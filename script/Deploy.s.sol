// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { DegenBox } from "@abracadabra/DegenBox.sol";
import { IBentoBoxV1 } from "@abracadabra/interfaces/IBentoBoxV1.sol";
import { CauldronV4 } from "@abracadabra/cauldrons/CauldronV4.sol";
import { ProxyOracle } from "@abracadabra/oracles/ProxyOracle.sol";
import { MarketLens } from "@abracadabra/lenses/MarketLens.sol";
import { IERC20 } from "@BoringSolidity/ERC20.sol";
import { FixedPriceOracle } from "@abracadabra/oracles/FixedPriceOracle.sol";
import { BaseScript } from "./Base.s.sol";
import { StableCoin } from "../src/tokens/StableCoin.sol";
import { ERC20 } from "../src/tokens/ERC20.sol";
import { WETH } from "../src/tokens/WETH.sol";
import { CauldronFactory } from "../src/cauldron/CauldronFactory.sol";
import { ChainLinkOracleAdaptor } from "../src/oracles/ChainLinkOracleAdaptor.sol";
import { ChainConfigHelper } from "../src/helpers/ChainConfigHelper.sol";

import { console2 } from "forge-std/console2.sol";

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
    error UnsupportedChain();

    uint64 public constant INTEREST_PER_SECOND = uint64((uint256(600) * 316_880_878) / 100);
    uint256 public constant LIQUIDATION_MULTIPLIER = uint256(600) * 1e1 + 1e5;
    uint256 public constant COLLATERIZATION_RATE = uint256(8000) * 1e1;
    uint256 public constant BORROW_OPENING_FEE = uint256(50) * 1e1;

    uint8 constant TOKEN_DECIMALS = 18;
    address constant ZERO_ADDRESS = address(0);

    // Deployed contracts
    StableCoin public stableCoin;
    ERC20 public sbtc;
    WETH public weth;
    DegenBox public degenBox;
    CauldronV4 public masterCauldron;
    ChainLinkOracleAdaptor public oracle;
    ProxyOracle public oracleProxy;
    CauldronFactory public cauldronFactory;
    address public sBTCMarket;
    MarketLens public marketLens;
    ChainConfigHelper public chainConfigHelper;

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
            ChainLinkOracleAdaptor,
            ProxyOracle,
            CauldronFactory,
            address,
            MarketLens
        )
    {
        chainConfigHelper = new ChainConfigHelper();

        // 1. Deploy tokens
        deployTokens();

        // 2. Deploy DegenBox and master cauldron
        deployDegenBoxAndMasterCauldron();

        // 3. Deploy Oracle (dynamic based on chain)
        deployOracle();

        // 4. Deploy CauldronFactory
        deployCauldronFactory();

        // 5. Deploy sBTC market
        deploySBTCMarket();

        // 6. Approve tokens for DegenBox
        approveTokensForDegenBox();

        // 7. Deploy MarketLens
        deployMarketLens();

        // 8. Optional
        prepareLiquidity();

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
        if (address(stableCoin) != ZERO_ADDRESS) revert AlreadyDeployed();

        // Deploy ScalarUSD
        stableCoin = new StableCoin("ScalarUSD", "sUSD", TOKEN_DECIMALS);
        emit TokenDeployed("ScalarUSD", address(stableCoin), "sUSD", TOKEN_DECIMALS);

        // Deploy sBTC
        sbtc = new ERC20("sBTC", "sBTC", TOKEN_DECIMALS);
        emit TokenDeployed("sBTC", address(sbtc), "sBTC", TOKEN_DECIMALS);

        // Deploy WETH
        weth = new WETH();
        emit TokenDeployed("WETH", address(weth), "WETH", TOKEN_DECIMALS);
    }

    function deployDegenBoxAndMasterCauldron() internal {
        if (address(degenBox) != ZERO_ADDRESS) revert AlreadyDeployed();
        if (address(stableCoin) == ZERO_ADDRESS) revert NotDeployed();

        // Deploy DegenBox
        degenBox = new DegenBox(IERC20(address(weth)));

        // Deploy Master CauldronV4
        masterCauldron = new CauldronV4(IBentoBoxV1(address(degenBox)), IERC20(address(stableCoin)), msg.sender);

        // Whitelist master contract
        degenBox.whitelistMasterContract(address(masterCauldron), true);

        emit DegenBoxDeployed(address(degenBox), address(masterCauldron));
    }

    function deployOracle() internal {
        if (address(oracle) != ZERO_ADDRESS) revert AlreadyDeployed();

        address chainOracle = chainConfigHelper.getBtcUsdOracle(block.chainid);

        address oracleAddress;

        // Deploy ProxyOracle
        oracleProxy = new ProxyOracle();

        if (chainOracle == ZERO_ADDRESS) {
            FixedPriceOracle fixedPriceOracle = new FixedPriceOracle("sBTC/sUSD", 5e12, TOKEN_DECIMALS);
            oracleAddress = address(fixedPriceOracle);
            oracleProxy.changeOracleImplementation(fixedPriceOracle);
        } else {
            // Use existing Chainlink oracle
            oracleAddress = chainOracle;
            oracle = new ChainLinkOracleAdaptor(oracleAddress, TOKEN_DECIMALS, "sBTC/sUSD", "sBTC/sUSD");
            oracleProxy.changeOracleImplementation(oracle);
        }

        emit OracleDeployed(
            address(oracle), address(oracleProxy), string(abi.encodePacked("sBTC/sUSD Oracle for ", "chain"))
        );
    }

    function deployCauldronFactory() internal {
        if (address(cauldronFactory) != ZERO_ADDRESS) revert AlreadyDeployed();
        if (address(masterCauldron) == ZERO_ADDRESS) revert NotDeployed();

        cauldronFactory = new CauldronFactory(address(masterCauldron), address(degenBox));
        emit CauldronFactoryDeployed(address(cauldronFactory), address(masterCauldron));
    }

    function deploySBTCMarket() internal {
        if (sBTCMarket != ZERO_ADDRESS) revert AlreadyDeployed();
        if (address(cauldronFactory) == ZERO_ADDRESS) revert NotDeployed();
        if (address(oracleProxy) == ZERO_ADDRESS) revert NotDeployed();

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
        if (address(degenBox) == ZERO_ADDRESS) revert NotDeployed();
        if (address(stableCoin) == ZERO_ADDRESS) revert NotDeployed();

        stableCoin.approve(address(degenBox), type(uint256).max);
        sbtc.approve(address(degenBox), type(uint256).max);
        weth.approve(address(degenBox), type(uint256).max);
    }

    function deployMarketLens() internal {
        if (address(marketLens) != ZERO_ADDRESS) revert AlreadyDeployed();

        marketLens = new MarketLens();
        emit MarketLensDeployed(address(marketLens));
    }

    function prepareLiquidity() internal {
        sbtc.mint(msg.sender, 1e3 ether);
        uint256 amount = 1e12 ether;
        stableCoin.mint(msg.sender, amount);
        degenBox.deposit(stableCoin, msg.sender, sBTCMarket, amount, 0);
    }
}
