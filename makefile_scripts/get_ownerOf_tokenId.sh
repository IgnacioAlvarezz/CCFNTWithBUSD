#!/bin/bash
cast decode-abi "ownerOf(uint256) external view returns (address)" $(cast call 0xA070C9cCCF2fda36b2bfe1903a7705aBe2A18399 "ownerOf(uint256)" $1 --rpc-url $SEPOLIA_RPC_URL)