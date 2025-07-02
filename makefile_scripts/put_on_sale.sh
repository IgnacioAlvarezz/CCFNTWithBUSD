#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

echo "--- Running put_on_sale.sh ---"

# Verify essential environment variables
if [ -z "$SEPOLIA_RPC_URL" ]; then echo "Error: SEPOLIA_RPC_URL is not set."; exit 1; fi
if [ -z "$BUYER_PRIVATE_KEY" ]; then echo "Error: BUYER_PRIVATE_KEY is not set."; exit 1; fi
if [ -z "$BUYER_ADDRESS" ]; then echo "Error: BUYER_ADDRESS is not set."; exit 1; fi

NFT_PRICE=$1
if [ -z "$NFT_PRICE" ]; then
    echo "Error: NFT_PRICE cannot be empty."
    exit 1
fi

echo "Loading contract addresses from .env_addresses..."
if [ -f .env_addresses ]; then
    source .env_addresses
else
    echo "Error: .env_addresses not found. Run 'make deploy' first."
    exit 1
fi

# Verify loaded contract addresses
if [ -z "$CCNFT_CONTRACT_ADDRESS" ]; then echo "Error: CCNFT_CONTRACT_ADDRESS not found in .env_addresses."; exit 1; fi

# Define CAST_COMMON within the script for consistency
CAST_COMMON="--rpc-url $SEPOLIA_RPC_URL --private-key"

read -p "Enter the tokenId to put on sale (e.g., from the previous 'buy' operation): " NFT_TO_SELL_ID

if [ -z "$NFT_TO_SELL_ID" ]; then
    echo "Error: NFT_TO_SELL_ID cannot be empty."
    exit 1
fi

echo "Simulating putOnSale operation for tokenId $NFT_TO_SELL_ID by $BUYER_ADDRESS..."
cast send "$CCNFT_CONTRACT_ADDRESS" "putOnSale(uint256,uint256)" "$NFT_TO_SELL_ID" "$NFT_PRICE" $CAST_COMMON "$BUYER_PRIVATE_KEY"
echo "Put on sale transaction sent for tokenId $NFT_TO_SELL_ID."

echo "--- put_on_sale.sh finished ---"
