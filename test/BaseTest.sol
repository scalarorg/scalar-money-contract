// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

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
import { VaultFactory } from "../src/cauldron/VaultFactory.sol";
import { Vault } from "../src/cauldron/Vault.sol";
import { ChainLinkOracleAdaptor } from "../src/oracles/ChainLinkOracleAdaptor.sol";
import { ChainConfigHelper } from "../src/helpers/ChainConfigHelper.sol";
import { console2 } from "forge-std/console2.sol";

abstract contract BaseTest is Test {
    address payable internal alice;
    address payable internal bob;
    address payable internal carol;
    address[] pranks;

    // Shared deployment state
    struct DeploymentState {
        StableCoin stableCoin;
        ERC20 sbtc;
        WETH weth;
        ProxyOracle oracleProxy;
        address vault;
        Vault masterContract;
        MarketLens marketLens;
        DegenBox degenBox;
        address deployer;
        ChainConfigHelper chainConfigHelper;
        VaultFactory vaultFactory;
    }

    DeploymentState internal deployment;

    // Market configuration constants
    uint64 public constant INTEREST_PER_SECOND = uint64((uint256(600) * 316_880_878) / 100);
    uint256 public constant LIQUIDATION_MULTIPLIER = uint256(600) * 1e1 + 1e5;
    uint256 public constant COLLATERIZATION_RATE = uint256(8000) * 1e1;
    uint256 public constant BORROW_OPENING_FEE = uint256(50) * 1e1;

    function setUp() public virtual {
        setUpNoMocks();
    }

    function setUpNoMocks() public virtual {
        popAllPranks();

        alice = createUser("alice", address(0x1), 100 ether);
        bob = createUser("bob", address(0x2), 100 ether);
        carol = createUser("carol", address(0x3), 100 ether);
    }

    function createUser(string memory label, address account, uint256 amount) internal returns (address payable) {
        vm.deal(account, amount);
        vm.label(account, label);
        return payable(account);
    }

    function pushPrank(address account) public {
        if (pranks.length > 0) {
            vm.stopPrank();
        }
        pranks.push(account);
        vm.startPrank(account);
    }

    function popPrank() public {
        if (pranks.length > 0) {
            vm.stopPrank();
            pranks.pop();

            if (pranks.length > 0) {
                vm.startPrank(pranks[pranks.length - 1]);
            }
        }
    }

    function popAllPranks() public {
        while (pranks.length > 0) {
            popPrank();
        }
    }

    function fork(string calldata chainId) internal returns (uint256 forkId) {
        try vm.createSelectFork(chainId) returns (uint256 id) {
            forkId = id;
        } catch {
            revert(string.concat("Failed to create fork for ", chainId));
        }
    }

    /// @notice Deploy the entire Scalar system following the deployment script pattern
    /// @param deployer The address that will deploy and own the contracts
    /// @return The deployment state containing all deployed contracts
    function deployScalarSystem(address deployer) internal returns (DeploymentState memory) {
        console2.log("Deploying Scalar system with deployer:", deployer);

        pushPrank(deployer);

        DeploymentState memory state;
        state.deployer = deployer;

        // Deploy in stages to avoid stack too deep
        _deployTokens(state);
        _deployOracle(state);
        _deployVaultSystem(state);
        _deployMarketAndLens(state);
        _approveTokens(state);
        _logAddresses(state);

        popPrank();
        return state;
    }

    function _deployTokens(DeploymentState memory state) private {
        state.chainConfigHelper = new ChainConfigHelper();
        state.stableCoin = new StableCoin("ScalarUSD", "sUSD", 18);
        state.sbtc = new ERC20("sBTC", "sBTC", 18);
        state.weth = new WETH();
    }

    function _deployOracle(DeploymentState memory state) private {
        state.oracleProxy = new ProxyOracle();
        address chainOracle = state.chainConfigHelper.getBtcUsdOracle(block.chainid);

        if (chainOracle == address(0)) {
            FixedPriceOracle fixedPriceOracle = new FixedPriceOracle("sBTC/sUSD", 1e13, 18);
            state.oracleProxy.changeOracleImplementation(fixedPriceOracle);
        } else {
            ChainLinkOracleAdaptor oracle = new ChainLinkOracleAdaptor(chainOracle, 18, "sBTC/sUSD", "sBTC/sUSD");
            state.oracleProxy.changeOracleImplementation(oracle);
        }
    }

    function _deployVaultSystem(DeploymentState memory state) private {
        state.degenBox = new DegenBox(IERC20(address(state.weth)));
        state.vaultFactory = new VaultFactory(address(state.degenBox), address(state.stableCoin));
        state.masterContract = state.vaultFactory.masterContract();
        state.degenBox.whitelistMasterContract(address(state.masterContract), true);
    }

    function _deployMarketAndLens(DeploymentState memory state) private {
        bytes memory initData = abi.encode(
            address(state.sbtc),
            address(state.oracleProxy),
            "",
            INTEREST_PER_SECOND,
            LIQUIDATION_MULTIPLIER,
            COLLATERIZATION_RATE,
            BORROW_OPENING_FEE
        );

        state.vault = state.vaultFactory.createVault(initData);
        state.marketLens = new MarketLens();
    }

    function _approveTokens(DeploymentState memory state) private {
        state.stableCoin.approve(address(state.degenBox), type(uint256).max);
        state.sbtc.approve(address(state.degenBox), type(uint256).max);
        state.weth.approve(address(state.degenBox), type(uint256).max);
    }

    function _logAddresses(DeploymentState memory state) private pure {
        console2.log("stableCoin:", address(state.stableCoin));
        console2.log("sbtc:", address(state.sbtc));
        console2.log("weth:", address(state.weth));
        console2.log("degenBox:", address(state.degenBox));
        console2.log("masterCauldron:", address(state.masterContract));
        console2.log("oracleProxy:", address(state.oracleProxy));
        console2.log("vaultFactory:", address(state.vaultFactory));
        console2.log("sBTCMarket:", state.vault);
        console2.log("marketLens:", address(state.marketLens));
    }

    /// @notice Set up user approvals for the deployed system
    /// @param user The user address to set up approvals for
    /// @param state The deployment state
    function setupUserApprovals(address user, DeploymentState memory state) internal {
        pushPrank(user);

        // Approve tokens for DegenBox
        state.stableCoin.approve(address(state.degenBox), type(uint256).max);
        state.sbtc.approve(address(state.degenBox), type(uint256).max);
        state.weth.approve(address(state.degenBox), type(uint256).max);

        // Set master contract approval for the user
        state.degenBox.setMasterContractApproval(user, address(state.masterContract), true, 0, 0x0, 0x0);

        popPrank();
    }

    /// @notice Prepare initial liquidity in the market (matches deployment script)
    /// @param state The deployment state
    function prepareLiquidity(DeploymentState memory state) internal {
        pushPrank(state.deployer);

        // Mint tokens for liquidity (matching the deployment script amounts)
        state.sbtc.mint(state.deployer, 1e3 ether);
        uint256 amount = 1e12 ether;
        state.stableCoin.mint(state.deployer, amount);
        state.degenBox.deposit(state.stableCoin, state.deployer, state.vault, amount, 0);

        console2.log("Liquidity prepared:");
        console2.log("- sBTC minted: 1e3 ether");
        console2.log("- sUSD minted and deposited:", amount);

        popPrank();
    }

    /// @notice Mint tokens to a user for testing
    /// @param user The user to mint tokens to
    /// @param state The deployment state
    /// @param stableCoinAmount Amount of stablecoin to mint
    /// @param sbtcAmount Amount of sBTC to mint
    /// @param ethAmount Amount of ETH to give (for WETH)
    function mintTokensToUser(
        address user,
        DeploymentState memory state,
        uint256 stableCoinAmount,
        uint256 sbtcAmount,
        uint256 ethAmount
    )
        internal
    {
        pushPrank(state.deployer);

        if (stableCoinAmount > 0) {
            state.stableCoin.mint(user, stableCoinAmount);
        }

        if (sbtcAmount > 0) {
            state.sbtc.mint(user, sbtcAmount);
        }

        popPrank();

        if (ethAmount > 0) {
            vm.deal(user, ethAmount);
        }
    }

    /// @notice Prepare a user with full setup (approvals and tokens)
    /// @param user The user to prepare
    /// @param state The deployment state
    /// @param stableCoinAmount Amount of stablecoin to mint
    /// @param sbtcAmount Amount of sBTC to mint
    /// @param ethAmount Amount of ETH to give
    function prepareUser(
        address user,
        DeploymentState memory state,
        uint256 stableCoinAmount,
        uint256 sbtcAmount,
        uint256 ethAmount
    )
        internal
    {
        setupUserApprovals(user, state);
        mintTokensToUser(user, state, stableCoinAmount, sbtcAmount, ethAmount);
    }
}
