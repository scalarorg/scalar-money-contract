#!/bin/bash

source "$(dirname "$0")/common.sh"

SCRIPT_NAME="Deploy"
NETWORK=${1:-"sepolia"}
shift 1
EXTRA_ARGS="$@"

source_env
check_env
set_network_config
info
run_forge_script "$SCRIPT_NAME.s.sol" $EXTRA_ARGS
