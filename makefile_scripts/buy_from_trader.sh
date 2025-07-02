#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

echo "--- Running buy.sh ---"

# Define NFT parameters, passed from Makefile on invocation
NFT_VALUE=$1
NFT_AMOUNT=$2
NFT_PRICE=$3

# Verify essential environment variables
if [ -z "$SEPOLIA_RPC_URL" ]; then echo "Error: SEPOLIA_RPC_URL is not set."; exit 1; fi
if [ -z "$BUYER_PRIVATE_KEY" ]; then echo "Error: BUYER_PRIVATE_KEY is not set."; exit 1; fi
if [ -z "$TRADER_ADDRESS" ]; then echo "Error: BUYER_ADDRESS is not set."; exit 1; fi
if [ -z "$NFT_VALUE" ]; then echo "Error: NFT_VALUE is not set."; exit 1; fi
if [ -z "$NFT_AMOUNT" ]; then echo "Error: NFT_AMOUNT is not set."; exit 1; fi


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

echo "Simulating buy operation by $TRADER_ADDRESS..."
cast send "$CCNFT_CONTRACT_ADDRESS" "buy(uint256,uint256)" "$NFT_VALUE" "$NFT_AMOUNT" $CAST_COMMON "$TRADER_PRIVATE_KEY"
echo "Buy transaction sent. You'll need to find the minted tokenId to proceed with 'put_on_sale'."
echo "Check the transaction on Etherscan for the 'Buy' event, or query contract's totalSupply() and ownerOf(latest_id)."

echo "--- buy.sh finished ---"
