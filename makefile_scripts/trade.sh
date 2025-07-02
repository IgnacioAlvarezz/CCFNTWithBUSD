#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

echo "--- Running trade.sh ---"

# Define NFT parameters, passed from Makefile on invocation
NFT_VALUE=$1
NFT_AMOUNT=$2
NFT_PRICE=$3

# Verify essential environment variables
if [ -z "$SEPOLIA_RPC_URL" ]; then echo "Error: SEPOLIA_RPC_URL is not set."; exit 1; fi
if [ -z "$OWNER_PRIVATE_KEY" ]; then echo "Error: OWNER_PRIVATE_KEY is not set."; exit 1; fi
if [ -z "$TRADER_PRIVATE_KEY" ]; then echo "Error: TRADER_PRIVATE_KEY is not set."; exit 1; fi
if [ -z "$TRADER_ADDRESS" ]; then echo "Error: TRADER_ADDRESS is not set."; exit 1; fi

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
CAST_COMMON_OWNER="--rpc-url $SEPOLIA_RPC_URL --private-key"
CAST_COMMON_TRADER="--rpc-url $SEPOLIA_RPC_URL --private-key"

read -p "Enter the tokenId to trade (must be currently 'On Sale'): " NFT_TO_TRADE_ID

if [ -z "$NFT_TO_TRADE_ID" ]; then
    echo "Error: NFT_TO_TRADE_ID cannot be empty."
    exit 1
fi


echo "Simulating trade operation for tokenId $NFT_TO_TRADE_ID by $TRADER_ADDRESS..."
cast send "$CCNFT_CONTRACT_ADDRESS" "trade(uint256)" "$NFT_TO_TRADE_ID" $CAST_COMMON_TRADER "$TRADER_PRIVATE_KEY"
echo "Trade transaction sent for tokenId $NFT_TO_TRADE_ID."

echo "--- trade.sh finished ---"
