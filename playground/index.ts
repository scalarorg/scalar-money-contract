import { createPublicClient, http } from 'viem';
import { sepolia } from 'viem/chains';
import MarketLens from '../out/MarketLens.sol/MarketLens.json';

const MARKET_LENS_ADDRESS = '0xd54C1e02D4Fe4D060A4Cb67EC83166FE689A076F';
const CAULDRON_ADDRESS = '0xA69F40152C1Ec5ceC093ACF3786Ad52DeA511f17';

const client = createPublicClient({
    chain: sepolia,
    transport: http(),
});

async function main() {
    const result = await client.readContract({
        address: MARKET_LENS_ADDRESS as `0x${string}`,
        abi: MarketLens.abi,
        functionName: 'getMarketInfoCauldronV3',
        args: [CAULDRON_ADDRESS],
    });

    console.log('Market Info:', result);
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});

const a =
{
    borrowFee: 50n,
    cauldron: "0xA69F40152C1Ec5ceC093ACF3786Ad52DeA511f17",
    collateralPrice: 100000000000000000000000n,
    interestPerYear: 600n,
    liquidationFee: 600n,
    marketMaxBorrow: 0n,
    maximumCollateralRatio: 8000n,
    oracleExchangeRate: 0n,
    totalBorrowed: 0n,
    totalCollateral: { amount: 0n, value: 1158473314246726482143603431918160393696660013887n },
    userMaxBorrow: 0n,
}