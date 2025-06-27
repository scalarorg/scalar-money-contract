#!/bin/bash

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

env_file=".env"
if [ -f "$env_file" ]; then
    export $(cat "$env_file" | grep -v '#' | sed 's/\r$//' | xargs)
else
    echo "${env_file} file not found"
    exit 1
fi

# Function to check required environment variables
check_env() {
    local missing=0

    if [ -z "$PRIVATE_KEY" ]; then
        echo -e "${RED}Error: PRIVATE_KEY is not set${NC}"
        missing=1
    fi

    if [ -z "$API_KEY_ETHERSCAN" ]; then
        echo -e "${RED}Error: API_KEY_ETHERSCAN is not set${NC}"
        missing=1
    fi

    if [ -z "$ALCHEMY_API_KEY" ]; then
        echo -e "${RED}Error: ALCHEMY_API_KEY is not set${NC}"
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
    *)
        echo -e "${RED}Error: Unsupported network '$NETWORK'${NC}"
        echo "Supported networks: mainnet, sepolia, bsctestnet, anvil"
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

# Function to deploy the contract
deploy() {
    echo -e "${GREEN}Deploying DeployScalar contract...${NC}"
    # Build Forge script command
    FORGE_CMD="forge script script/DeployScalar.s.sol \
        --chain-id $CHAIN_ID \
        --rpc-url $NETWORK \
        --private-key $PRIVATE_KEY \
        --broadcast 
        --verify"
        
    # Execute the command
    echo "Executing: $FORGE_CMD"

    read -p "Continue with deployment? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo "Deployment cancelled"
        exit 0
    fi

    eval $FORGE_CMD
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Deployment successful!${NC}"
    else
        echo -e "${RED}Deployment failed!${NC}"
        exit 1
    fi
}

# Main script execution
main() {
    # Parse arguments
    NETWORK=${1:-"sepolia"}

    # Check required environment variables
    check_env
    # Set network configuration
    set_network_config
    # Display deployment information
    info
    # Deploy the contract
    deploy
}

# Execute main function
main "$@"
