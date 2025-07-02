#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

echo "--- Running approve_tokens.sh ---"

# Verify essential environment variables
if [ -z "$SEPOLIA_RPC_URL" ]; then echo "Error: SEPOLIA_RPC_URL is not set."; exit 1; fi
if [ -z "$BUYER_PRIVATE_KEY" ]; then echo "Error: BUYER_PRIVATE_KEY is not set."; exit 1; fi
if [ -z "$BUYER_ADDRESS" ]; then echo "Error: BUYER_ADDRESS is not set."; exit 1; fi

echo "Loading contract addresses from .env_addresses..."
if [ -f .env_addresses ]; then
    source .env_addresses
else
    echo "Error: .env_addresses not found. Run 'make deploy' first."
    exit 1
fi

# Verify loaded contract addresses
if [ -z "$BUSD_CONTRACT_ADDRESS" ]; then echo "Error: BUSD_CONTRACT_ADDRESS not found in .env_addresses."; exit 1; fi
if [ -z "$CCNFT_CONTRACT_ADDRESS" ]; then echo "Error: CCNFT_CONTRACT_ADDRESS not found in .env_addresses."; exit 1; fi

# Define CAST_COMMON within the script for consistency
CAST_COMMON="--rpc-url $SEPOLIA_RPC_URL --private-key"

echo "Buyer ($BUYER_ADDRESS) approving CCNFT ($CCNFT_CONTRACT_ADDRESS) to spend BUSD tokens..."
# Approves a very large amount to cover multiple transactions
cast send "$BUSD_CONTRACT_ADDRESS" "approve(address,uint256)" "$CCNFT_CONTRACT_ADDRESS" 1000000000000000000000000000 $CAST_COMMON "$BUYER_PRIVATE_KEY"
echo "Approval complete."

echo "--- approve_tokens.sh finished ---"
