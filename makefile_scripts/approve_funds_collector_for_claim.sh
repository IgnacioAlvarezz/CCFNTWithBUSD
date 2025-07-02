#!/bin/bash
set -e

echo "--- Running approve_funds_collector_for_claim.sh ---"

# Verify essential environment variables
if [ -z "$SEPOLIA_RPC_URL" ]; then echo "Error: SEPOLIA_RPC_URL is not set."; exit 1; fi
if [ -z "$OWNER_PRIVATE_KEY" ]; then echo "Error: OWNER_PRIVATE_KEY is not set."; exit 1; fi
if [ -z "$OWNER_ADDRESS" ]; then echo "Error: OWNER_ADDRESS is not set."; exit 1; fi

echo "Loading contract addresses from .env_addresses..."
if [ -f .env_addresses ]; then
    source .env_addresses
else
    echo "Error: .env_addresses not found. Run 'make deploy' first."
    exit 1
fi

if [ -z "$BUSD_CONTRACT_ADDRESS" ]; then echo "Error: BUSD_CONTRACT_ADDRESS not found in .env_addresses."; exit 1; fi

CAST_COMMON="--rpc-url $SEPOLIA_RPC_URL --private-key"

echo "Funds Collector (Owner: $OWNER_ADDRESS) approving itself to spend BUSD for claim operations..."
cast send "$BUSD_CONTRACT_ADDRESS" "approve(address,uint256)" "$OWNER_ADDRESS" 1000000000000000000000000000 $CAST_COMMON "$OWNER_PRIVATE_KEY"
cast send "$BUSD_CONTRACT_ADDRESS" "approve(address,uint256)" "$CCNFT_CONTRACT_ADDRESS" 1000000000000000000000000000 $CAST_COMMON "$OWNER_PRIVATE_KEY"

echo "Funds Collector approval for claim complete."

echo "--- approve_funds_collector_for_claim.sh finished ---"