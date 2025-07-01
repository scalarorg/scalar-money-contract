#!/bin/bash

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

source_env() {
    local env_file=".env"
    if [ "$NETWORK" == "localhost" ]; then
        env_file=".env.local"
    fi
    if [ -f "$env_file" ]; then
        export $(cat "$env_file" | grep -v '#' | sed 's/\r$//' | xargs)
    else
        echo -e "${env_file} file not found"
        exit 1
    fi
}

# Function to check required environment variables
check_env() {
    local missing=0

    if [ -z "$API_KEY_ETHERSCAN" ]; then
        echo -e "${RED}Error: API_KEY_ETHERSCAN is not set${NC}"
        missing=1
    fi

    if [ -z "$ALCHEMY_API_KEY" ]; then
        echo -e "${RED}Error: ALCHEMY_API_KEY is not set${NC}"
        missing=1
    fi

    if [ -z "$KEYSTORE_ACCOUNT" ]; then
        echo -e "${RED}Error: ACCOUNT is not set${NC}"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        exit 1
    fi
}

# Function to set network-specific configurations
set_network_config() {
    case "$NETWORK" in
    "mainnet")
        CHAIN_ID=1
        ;;
    "sepolia")
        CHAIN_ID=11155111
        ;;
    "bsctestnet")
        CHAIN_ID=97
        ;;
    "localhost")
        CHAIN_ID=31337
        ;;
    *)
        echo -e "${RED}Error: Unsupported network '$NETWORK'${NC}"
        echo "Supported networks: mainnet, sepolia, bsctestnet, localhost"
        exit 1
        ;;
    esac
}

# Function to display information
info() {
    echo -e "\n${GREEN}════════════════════════════════════ DEPLOYMENT CONFIG ════════════════════════════════════${NC}"
    echo -e "${BLUE}NETWORK:${NC}            $NETWORK"
    echo -e "${BLUE}RPC_URL:${NC}            $RPC_URL"
    echo -e "${BLUE}VERIFIER_URL:${NC}       $VERIFIER_URL"
    echo -e "${BLUE}API_KEY_ETHERSCAN:${NC}    $API_KEY_ETHERSCAN"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════════════════════${NC}\n"
}

run_forge_script() {
    local script_name=$1
    shift
    local extra_args="$@"

    echo -e "${GREEN}Running Forge script: $script_name${NC}"

    FORGE_CMD="forge script script/$script_name \
            --chain-id $CHAIN_ID \
            --rpc-url $NETWORK \
            --broadcast \
            --verify \
            --account $KEYSTORE_ACCOUNT $extra_args"

    if [ "$NETWORK" == "localhost" ]; then
        FORGE_CMD="forge script script/$script_name \
            --chain-id $CHAIN_ID \
            --rpc-url $NETWORK \
            --broadcast \
            --account $KEYSTORE_ACCOUNT $extra_args"
    fi

    echo "Executing: $FORGE_CMD"

    read -p "Continue with script execution? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo "Script execution cancelled"
        exit 0
    fi

    eval $FORGE_CMD
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Script executed successfully!${NC}"
    else
        echo -e "${RED}Script execution failed!${NC}"
        exit 1
    fi
}
