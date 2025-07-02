.PHONY: all deploy configure fund_accounts approve_tokens buy put_on_sale trade claim clean help
SHELL := bash
# ==============================================================================
# Configuration Variables
# Replace the placeholder values with your actual data or set them as environment variables.
# ==============================================================================
SEPOLIA_RPC_URL := $(SEPOLIA_RPC_URL)
$(info Using SEPOLIA_RPC_URL=$(SEPOLIA_RPC_URL))
	

# Values for operations (in Wei, 1 Ether = 10^18 Wei)
NFT_VALUE=1000000000000000000 # 1 BUSD (1e18) as the base value for a new NFT
NFT_AMOUNT=1 # Number of NFTs to buy in one transaction
NFT_PRICE=2000000000000000000 # 2 BUSD (2e18) as the selling price for an NFT in trade


# ==============================================================================
# Helper Commands
# ==============================================================================
CAST_COMMON := --rpc-url $(SEPOLIA_RPC_URL) --private-key

# ==============================================================================
# Simulation Targets
# ==============================================================================

# Runs the full simulation flow: deploy, configure, fund, approve, buy, put-on-sale, trade, claim
all: deploy configure fund_accounts approve_tokens buy put_on_sale trade claim

# Compiles the contracts
build:
	@echo "Building contracts..."
	@forge build

# Deploys BUSD and CCNFT contracts
# Stores addresses in a temporary file '.env_addresses' for subsequent steps
deploy: build
	@echo "Executing deployment script..."
	./makefile_scripts/deploy.sh

# Configures the deployed CCNFT contract (actions performed by the contract owner)
configure:
	@echo "Configuring CCNFT contract..."
	./makefile_scripts/configure.sh	
# Also approve the funds collector to claim NFTs
	./makefile_scripts/approve_funds_collector_for_claim.sh 
	@echo "CCNFT configuration complete."

# Funds the buyer's account with BUSD tokens from the owner's initial supply (from BUSD contract)
fund_accounts:
	./makefile_scripts/fund_accounts.sh
	./makefile_scripts/approve_funds_collector_for_claim.sh
	@echo "Fund accounts complete."

# Buyer approves the CCNFT contract to spend their BUSD tokens
approve_tokens:
	./makefile_scripts/approve_tokens.sh	
	@echo "Approval of Buyer complete."

# Trader approves the CCNFT contract to spend their BUSD tokens, also approves the BUSD contract for claims.
approve_tokens_trader:
	./makefile_scripts/approve_tokens_trader.sh	
	@echo "Approval of Trader complete."

# Simulates a buy operation (buyer purchases NFTs from the contract)
buy:
	./makefile_scripts/buy.sh ${NFT_VALUE} ${NFT_AMOUNT} ${NFT_PRICE}	
	@echo "Buy transaction sent. You'll need to find the minted tokenId to proceed with 'put_on_sale'."

# Simulates buying from the trader account instead of the buyer account
buy_from_trader:
	./makefile_scripts/buy_from_trader.sh ${NFT_VALUE} ${NFT_AMOUNT} ${NFT_PRICE}	
	@echo "Buy transaction sent. You'll need to find the minted tokenId to proceed with 'put_on_sale'."

# Simulates putting an NFT on sale (by the buyer who now owns it)
put_on_sale:
	./makefile_scripts/put_on_sale.sh ${NFT_PRICE}
	@echo "Put on sale operation complete. The NFT is now available for trade."

# Simulates a trade operation (the trader account buys the NFT from the current owner)
trade:
	./makefile_scripts/trade.sh ${NFT_VALUE} ${NFT_AMOUNT} ${NFT_PRICE}	
	@echo "Trade operation complete. The NFT has been transferred to the trader."

claim:
	./makefile_scripts/claim.sh
	@echo "Claim operation complete. The NFT has been burned and its value reclaimed."

# Cleans up build artifacts and deployed addresses file
clean:
	@echo "Cleaning up build artifacts and deployed addresses..."
	@rm -rf out
	@rm -rf cache
	@rm -f .env_addresses
	@echo "Clean complete."

# Displays help information
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all                 - Runs the full simulation flow (deploy, configure, fund, approve, buy, put-on-sale, trade, claim)"
	@echo "  build               - Compiles the smart contracts."
	@echo "  deploy              - Deploys BUSD and CCNFT contracts to Sepolia, stores addresses in .env_addresses."
	@echo "  configure           - Configures the deployed CCNFT contract (sets tokens, collectors, enables functionalities)."
	@echo "  fund_accounts       - Funds the BUYER_ADDRESS with BUSD tokens from the owner."
	@echo "  approve_tokens      - Buyer approves CCNFT contract to spend their BUSD tokens."
	@echo "  buy                 - Simulates a buy operation (Buyer purchases NFTs from the contract)."
	@echo "  put_on_sale         - Simulates putting a newly acquired NFT on sale (requires tokenId input)."
	@echo "  trade               - Simulates a trade operation (TRADER buys NFT from BUYER, requires tokenId input)."
	@echo "  claim               - Simulates claiming (burning) an NFT to reclaim its value (requires tokenId input)."
	@echo "  clean               - Removes build artifacts and the .env_addresses file."
	@echo "  help                - Displays this help message."
	@echo ""
	@echo "Configuration:"
	@echo "  Set SEPOLIA_RPC_URL, OWNER_PRIVATE_KEY, BUYER_PRIVATE_KEY, TRADER_PRIVATE_KEY"
	@echo "  as environment variables or directly in the Makefile."
	@echo "  Replace %...% placeholders with actual values."
