#!/bin/bash

# Compile contracts
echo "Compiling contracts"
forge build


# forge script script/DeployEverything.s.sol:Deploy --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL 

# Copy all ABI files to ../frontend/src/generated/abi (all .json but not .dbg.json in all subdirectories of artifacts/contracts)
echo "Copying ABI files to ../optistable-frontend/src/shared/abi"
find out/ -name "Policy*.json" ! -name "*.dbg.json" -exec cp {} ../optistable-frontend/src/shared/abi \;
find out/ -name "IPolicy*.json" ! -name "*.dbg.json" -exec cp {} ../optistable-frontend/src/shared/abi \;
find out/ -name "Oracle*.json" ! -name "*.dbg.json" -exec cp {} ../optistable-frontend/src/shared/abi \;
find out/ -name "IOracle*.json" ! -name "*.dbg.json" -exec cp {} ../optistable-frontend/src/shared/abi \;
find out/ -name "Generic*.json" ! -name "*.dbg.json" -exec cp {} ../optistable-frontend/src/shared/abi \;


# orge script script/DeployEverything.s.sol:Deploy --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL

#TODO extract policy address from output and replace in frontend;