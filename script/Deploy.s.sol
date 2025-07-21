// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { DegenBox } from "@abracadabra/DegenBox.sol";
import { ProxyOracle } from "@abracadabra/oracles/ProxyOracle.sol";
import { MarketLens } from "@abracadabra/lenses/MarketLens.sol";
import { IERC20 } from "@BoringSolidity/ERC20.sol";
import { FixedPriceOracle } from "@abracadabra/oracles/FixedPriceOracle.sol";
import { StableCoin } from "../src/tokens/StableCoin.sol";
import { ERC20 } from "../src/tokens/ERC20.sol";
import { WETH } from "../src/tokens/WETH.sol";
import { VaultFactory } from "../src/cauldron/VaultFactory.sol";
import { ChainLinkOracleAdaptor } from "../src/oracles/ChainLinkOracleAdaptor.sol";
import { ChainConfigHelper } from "../src/helpers/ChainConfigHelper.sol";
import { BaseScript } from "./Base.s.sol";

import { console2 } from "forge-std/console2.sol";

contract ScalarSystemDeployScript is BaseScript {
    // Events for better deployment tracking
    event TokenDeployed(string name, address indexed token, string symbol, uint8 decimals);
    event DegenBoxDeployed(address indexed degenBox, address indexed masterCauldron);
    event OracleDeployed(address indexed oracle, address indexed proxy, string description);
    event VaultFactoryDeployed(address indexed factory);
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
    ChainLinkOracleAdaptor public oracle;
    ProxyOracle public oracleProxy;
    VaultFactory public vaultFactory;
    address public vault;
    MarketLens public marketLens;
    ChainConfigHelper public chainConfigHelper;

    // Deployment state tracking
    bool public deployed;

    modifier onlyOnce() {
        if (deployed) revert AlreadyDeployed();
        _;
        deployed = true;
    }

    constructor() {
        chainConfigHelper = new ChainConfigHelper();
    }

    function run() external broadcast returns (address, StableCoin, ERC20, MarketLens, ProxyOracle) {
        // 1. Deploy tokens
        deployTokens();

        // 2. Deploy Oracle (dynamic based on chain)
        deployOracle();

        // 3. Deploy DegenBox and master cauldron
        deployDegenBoxAndVault();

        // 4. Approve tokens for DegenBox
        approveTokensForDegenBox();

        // 5. Deploy MarketLens
        deployMarketLens();

        // 6. Optional
        prepareLiquidity();

        return (vault, stableCoin, sbtc, marketLens, oracleProxy);
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

    function deployDegenBoxAndVault() internal {
        if (address(degenBox) != ZERO_ADDRESS) revert AlreadyDeployed();
        if (address(stableCoin) == ZERO_ADDRESS) revert NotDeployed();
        if (address(vaultFactory) != ZERO_ADDRESS) revert AlreadyDeployed();
        if (address(oracleProxy) == ZERO_ADDRESS) revert NotDeployed();
        if (vault != ZERO_ADDRESS) revert AlreadyDeployed();

        vaultFactory = new VaultFactory(address(degenBox), address(stableCoin));
        emit VaultFactoryDeployed(address(vaultFactory));

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

        vault = vaultFactory.createVault(initData);

        emit MarketDeployed(vault, address(sbtc), address(oracleProxy));

        // Deploy DegenBox
        degenBox = new DegenBox(IERC20(address(weth)));

        // Deploy Master CauldronV4

        // Whitelist master contract
        degenBox.whitelistMasterContract(address(vaultFactory.masterContract()), true);

        emit DegenBoxDeployed(address(degenBox), address(vaultFactory.masterContract()));
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
        degenBox.deposit(stableCoin, msg.sender, vault, amount, 0);
    }
}
