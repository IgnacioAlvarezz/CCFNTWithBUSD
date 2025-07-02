#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

echo "--- Running claim.sh ---"

# Verify essential environment variables
if [ -z "$SEPOLIA_RPC_URL" ]; then echo "Error: SEPOLIA_RPC_URL is not set."; exit 1; fi
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
if [ -z "$CCNFT_CONTRACT_ADDRESS" ]; then echo "Error: CCNFT_CONTRACT_ADDRESS not found in .env_addresses."; exit 1; fi

# Define CAST_COMMON within the script for consistency
CAST_COMMON="--rpc-url $SEPOLIA_RPC_URL --private-key"

read -p "Enter the tokenId to claim (must be owned by the Trader): " NFT_TO_CLAIM_ID

if [ -z "$NFT_TO_CLAIM_ID" ]; then
    echo "Error: NFT_TO_CLAIM_ID cannot be empty."
    exit 1
fi

echo "Simulating claim operation for tokenId $NFT_TO_CLAIM_ID by Trader ($TRADER_ADDRESS)..."
cast send "$CCNFT_CONTRACT_ADDRESS" "claim(uint256[])" "[$NFT_TO_CLAIM_ID]" $CAST_COMMON "$TRADER_PRIVATE_KEY"
echo "Claim transaction sent for tokenId $NFT_TO_CLAIM_ID."

echo "--- claim.sh finished ---"
