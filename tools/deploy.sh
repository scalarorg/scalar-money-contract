#!/bin/bash

source "$(dirname "$0")/common.sh"

SCRIPT_NAME="Deploy.s.sol"
NETWORK=${1:-"sepolia"}
shift 1
EXTRA_ARGS="$@"

check_env
set_network_config
info
run_forge_script "$SCRIPT_NAME" $EXTRA_ARGS
