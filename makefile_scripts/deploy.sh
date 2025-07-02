#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

echo "--- Running deploy.sh ---"

# These variables are expected to be set in the environment by the Makefile
# For standalone testing, you might need to export them:
# export SEPOLIA_RPC_URL="YOUR_RPC_URL"
# export OWNER_PRIVATE_KEY="YOUR_PRIVATE_KEY"

if [ -z "$SEPOLIA_RPC_URL" ]; then
    echo "Error: SEPOLIA_RPC_URL is not set. Please set it as an environment variable."
    exit 1
fi
if [ -z "$OWNER_PRIVATE_KEY" ]; then
    echo "Error: OWNER_PRIVATE_KEY is not set. Please set it as an environment variable."
    exit 1
fi

echo "Deploying BUSD (ERC20 token)..."
# Capture full forge create output, including potential errors, and ensure script continues even on forge error
FORGE_BUSD_OUTPUT=$(forge create --broadcast --rpc-url "$SEPOLIA_RPC_URL" --private-key "$OWNER_PRIVATE_KEY" src/BUSD.sol:BUSD 2>&1 || true)
# Print the full forge output for debugging/visibility
echo "$FORGE_BUSD_OUTPUT"
# Extract the deployed address
BUSD_ADDR=$(echo "$FORGE_BUSD_OUTPUT" | grep "Deployed to:" | awk '{print $3}')

# Check if address was successfully extracted
if [ -z "$BUSD_ADDR" ]; then
    echo "Error: BUSD contract address not found in forge output. Please check your RPC URL and private key, and ensure the contract compiles correctly. Full forge output above."
    exit 1
fi
echo "BUSD_CONTRACT_ADDRESS=$BUSD_ADDR" > .env_addresses
echo "Successfully deployed BUSD at: $BUSD_ADDR"

echo "Deploying CCNFT..."
# Capture full forge create output, including potential errors, and ensure script continues even on forge error
FORGE_CCNFT_OUTPUT=$(forge create --broadcast --rpc-url "$SEPOLIA_RPC_URL" --private-key "$OWNER_PRIVATE_KEY" src/CCNFT.sol:CCNFT --constructor-args "MyCCNFT" "CCNFT" 2>&1 || true)
# Print the full forge output for debugging/visibility
echo "$FORGE_CCNFT_OUTPUT"
# Extract the deployed address
CCNFT_ADDR=$(echo "$FORGE_CCNFT_OUTPUT" | grep "Deployed to:" | awk '{print $3}')

# Check if address was successfully extracted
if [ -z "$CCNFT_ADDR" ]; then
    echo "Error: CCNFT contract address not found in forge output. Please check your RPC URL and private key, and ensure the contract compiles correctly. Full forge output above."
    exit 1
fi
echo "CCNFT_CONTRACT_ADDRESS=$CCNFT_ADDR" >> .env_addresses
echo "Successfully deployed CCNFT at: $CCNFT_ADDR"

echo "--- deploy.sh finished ---"
