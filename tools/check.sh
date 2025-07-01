#!/usr/bin/env bash
if [ -f .env.sepolia ]; then
    export $(cat .env.sepolia | grep -v '#' | sed 's/\r$//' | xargs)
else
    echo ".env.sepolia file not found"
    exit 1
fi

pending-tx() {
    curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["0x982321eb5693cdbAadFfe97056BEce07D09Ba49f", "pending"],"id":1}' "${RPC_URL}"
}

"$@"
