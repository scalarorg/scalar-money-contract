// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

/**
 * @title ChainConfigHelper
 * @dev Helper contract for managing chain configurations
 */
contract ChainConfigHelper {
    struct ChainlinkOracleConfig {
        address btcUsdOracle;
        address ethUsdOracle;
        address linkUsdOracle;
    }
    // Add more oracle pairs as needed

    // Comprehensive chain configurations
    mapping(uint256 => ChainlinkOracleConfig) public chainlinkOracles;

    constructor() {
        chainlinkOracles[1] = ChainlinkOracleConfig({
            btcUsdOracle: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c,
            ethUsdOracle: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
            linkUsdOracle: 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c
        });

        // Sepolia Testnet (Chain ID: 11155111)
        chainlinkOracles[11_155_111] = ChainlinkOracleConfig({
            btcUsdOracle: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            ethUsdOracle: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            linkUsdOracle: 0xc59E3633BAAC79493d908e63626716e204A45EdF
        });

        // Polygon Mainnet (Chain ID: 137)
        chainlinkOracles[137] = ChainlinkOracleConfig({
            btcUsdOracle: 0xc907E116054Ad103354f2D350FD2514433D57F6f,
            ethUsdOracle: 0xF9680D99D6C9589e2a93a78A04A279e509205945,
            linkUsdOracle: 0xd9FFdb71EbE7496cC440152d43986Aae0AB76665
        });

        // Arbitrum One (Chain ID: 42161)
        chainlinkOracles[42_161] = ChainlinkOracleConfig({
            btcUsdOracle: 0x6ce185860a4963106506C203335A2910413708e9,
            ethUsdOracle: 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612,
            linkUsdOracle: 0x86E53CF1B870786351Da77A57575e79CB55812CB
        });

        // BSC Mainnet (Chain ID: 56)
        chainlinkOracles[56] = ChainlinkOracleConfig({
            btcUsdOracle: 0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf,
            ethUsdOracle: 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e,
            linkUsdOracle: 0xca236E327F629f9Fc2c30A4E95775EbF0B89fac8
        });

        // Avalanche C-Chain (Chain ID: 43114)
        chainlinkOracles[43_114] = ChainlinkOracleConfig({
            btcUsdOracle: 0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743,
            ethUsdOracle: 0x976B3D034E162d8bD72D6b9C989d545b839003b0,
            linkUsdOracle: 0x49ccd9ca821EfEab2b98c60dC60F518E765EDe9a
        });

        // Optimism (Chain ID: 10)
        chainlinkOracles[10] = ChainlinkOracleConfig({
            btcUsdOracle: 0xD702DD976Fb76Fffc2D3963D037dfDae5b04E593,
            ethUsdOracle: 0x13e3Ee699D1909E989722E753853AE30b17e08c5,
            linkUsdOracle: 0xCc232dcFAAE6354cE191Bd574108c1aD03f86450
        });

        // Base (Chain ID: 8453)
        chainlinkOracles[8453] = ChainlinkOracleConfig({
            btcUsdOracle: 0x64c911996D3c6aC71f9b455B1E8E7266BcbD848F,
            ethUsdOracle: 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70,
            linkUsdOracle: 0x9A7FB1b3950837a8D9b40517626E11D4127C098C
        });
    }

    function getBtcUsdOracle(uint256 chainId) external view returns (address) {
        return chainlinkOracles[chainId].btcUsdOracle;
    }

    function getEthUsdOracle(uint256 chainId) external view returns (address) {
        return chainlinkOracles[chainId].ethUsdOracle;
    }

    function getLinkUsdOracle(uint256 chainId) external view returns (address) {
        return chainlinkOracles[chainId].linkUsdOracle;
    }

    function getAllOracles(uint256 chainId) external view returns (ChainlinkOracleConfig memory) {
        return chainlinkOracles[chainId];
    }

    function isChainSupported(uint256 chainId) external view returns (bool) {
        return chainlinkOracles[chainId].btcUsdOracle != address(0);
    }
}
