#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

echo "--- Running fund_accounts.sh ---"

# Verify essential environment variables
if [ -z "$SEPOLIA_RPC_URL" ]; then echo "Error: SEPOLIA_RPC_URL is not set."; exit 1; fi
if [ -z "$OWNER_PRIVATE_KEY" ]; then echo "Error: OWNER_PRIVATE_KEY is not set."; exit 1; fi
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

# Define CAST_COMMON within the script for consistency
CAST_COMMON="--rpc-url $SEPOLIA_RPC_URL --private-key"

echo "Funding buyer ($BUYER_ADDRESS) with BUSD tokens..."
cast send "$BUSD_CONTRACT_ADDRESS" "transfer(address,uint256)" "$BUYER_ADDRESS" 100000000000000000000 $CAST_COMMON "$OWNER_PRIVATE_KEY"
echo "Buyer funded with 100 BUSD tokens."

echo "Funding trader ($TRADER_ADDRESS) with BUSD tokens..."
cast send "$BUSD_CONTRACT_ADDRESS" "transfer(address,uint256)" "$TRADER_ADDRESS" 100000000000000000000 $CAST_COMMON "$OWNER_PRIVATE_KEY"
echo "Trader funded with 100 BUSD tokens."

echo "--- fund_accounts.sh finished ---"
