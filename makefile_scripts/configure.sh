#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

echo "--- Running configure.sh ---"


# Values for operations (in Wei, 1 Ether = 10^18 Wei)
NFT_VALUE=1000000000000000000 # 1 BUSD (1e18) as the base value for a new NFT
NFT_AMOUNT=1 # Number of NFTs to buy in one transaction
NFT_PRICE=2000000000000000000 # 2 BUSD (2e18) as the selling price for an NFT in trade

# These variables are expected to be set in the environment by the Makefile
# For standalone testing, you might need to export them manually:
# export SEPOLIA_RPC_URL="YOUR_RPC_URL"
# export OWNER_PRIVATE_KEY="YOUR_PRIVATE_KEY"
# export OWNER_ADDRESS="YOUR_OWNER_ADDRESS"
# export NFT_VALUE="1000000000000000000"
# Verify essential environment variables
if [ -z "$SEPOLIA_RPC_URL" ]; then echo "Error: SEPOLIA_RPC_URL is not set."; exit 1; fi
if [ -z "$OWNER_PRIVATE_KEY" ]; then echo "Error: OWNER_PRIVATE_KEY is not set."; exit 1; fi
if [ -z "$OWNER_ADDRESS" ]; then echo "Error: OWNER_ADDRESS is not set."; exit 1; fi
if [ -z "$NFT_VALUE" ]; then echo "Error: NFT_VALUE is not set."; exit 1; fi

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

echo "Configuring CCNFT contract at $CCNFT_CONTRACT_ADDRESS (Owner: $OWNER_ADDRESS)..."
echo "Setting BUSD token address for funds..."
cast send "$CCNFT_CONTRACT_ADDRESS" "setFundsToken(address)" "$BUSD_CONTRACT_ADDRESS" $CAST_COMMON "$OWNER_PRIVATE_KEY"

echo "Setting funds and fees collectors (to owner address for simplicity)..."
cast send "$CCNFT_CONTRACT_ADDRESS" "setFundsCollector(address)" "$OWNER_ADDRESS" $CAST_COMMON "$OWNER_PRIVATE_KEY"
cast send "$CCNFT_CONTRACT_ADDRESS" "setFeesCollector(address)" "$OWNER_ADDRESS" $CAST_COMMON "$OWNER_PRIVATE_KEY"

echo "Enabling buy, claim, trade functionalities..."
cast send "$CCNFT_CONTRACT_ADDRESS" "setCanBuy(bool)" true $CAST_COMMON "$OWNER_PRIVATE_KEY"
cast send "$CCNFT_CONTRACT_ADDRESS" "setCanClaim(bool)" true $CAST_COMMON "$OWNER_PRIVATE_KEY"
cast send "$CCNFT_CONTRACT_ADDRESS" "setCanTrade(bool)" true $CAST_COMMON "$OWNER_PRIVATE_KEY"

echo "Setting max value to raise (a very large number) and adding a valid NFT value..."
cast send "$CCNFT_CONTRACT_ADDRESS" "setMaxValueToRaise(uint256)" 1000000000000000000000000000 $CAST_COMMON "$OWNER_PRIVATE_KEY"
cast send "$CCNFT_CONTRACT_ADDRESS" "addValidValues(uint256)" "$NFT_VALUE" $CAST_COMMON "$OWNER_PRIVATE_KEY"

echo "Setting batch count and transaction fees..."
cast send "$CCNFT_CONTRACT_ADDRESS" "setMaxBatchCount(uint16)" 10 $CAST_COMMON "$OWNER_PRIVATE_KEY"
cast send "$CCNFT_CONTRACT_ADDRESS" "setBuyFee(uint16)" 100 $CAST_COMMON "$OWNER_PRIVATE_KEY" # 1% (100 basis points / 10000)
cast send "$CCNFT_CONTRACT_ADDRESS" "setTradeFee(uint16)" 50 $CAST_COMMON "$OWNER_PRIVATE_KEY" # 0.5% (50 basis points / 10000)
cast send "$CCNFT_CONTRACT_ADDRESS" "setProfitToPay(uint32)" 0 $CAST_COMMON "$OWNER_PRIVATE_KEY" # 0% extra profit for claim for simplicity
echo "CCNFT configuration complete."

echo "--- configure.sh finished ---"
