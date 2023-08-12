#!/bin/bash

forge build
if [[ $? -neq 0 ]]; then
    echo "forge build failed, cancelling deployment"
    exit 1
fi
# Deploy source LayerZero contract to op goerli:
echo "Deploying LayerZero source chain contract to op goerli"
OP_GOERLI_LZ_CHAIN_ID=10132 # Sender chain
ETH_GOERLI_LZ_CHAIN_ID=10121 # Recipient chain
LAYER_ZERO_SOURCE_CONTRACT=0x580e79C5797B66101C248f8eaD0cC3f5a7d59b33
# LAYER_ZERO_SOURCE_CONTRACT=$(SYMBOL=USDC IS_DEST_DEPLOYMENT=false forge script script/DeployLayerZeroPriceFetcher.s.sol:Deploy --private-key $PRIVATE_KEY --broadcast --rpc-url $OP_GOERLI_RPC_URL | grep "Contract Address:" | awk '{print $NF}')
echo LAYER_ZERO_SOURCE_CONTRACT=$LAYER_ZERO_SOURCE_CONTRACT

# Deploy destination LayerZero contract to eth goerli:
echo "Deploying LayerZero destination chain contract to eth goerli"
LAYER_ZERO_DEST_CONTRACT=0x6B94C911FAcC7f3c360ECA1c78bF672BE7CC487B
# LAYER_ZERO_DEST_CONTRACT=$(SYMBOL=USDC \
#     LZ_SOURCE_CONTRACT=$LAYER_ZERO_SOURCE_CONTRACT \
#     LZ_SOURCE_CHAIN_ID=$OP_GOERLI_LZ_CHAIN_ID \
#     IS_DEST_DEPLOYMENT=true \
#     forge script script/DeployLayerZeroPriceFetcher.s.sol:Deploy --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL  | grep "Contract Address:" | awk '{print $NF}')
echo LAYER_ZERO_DEST_CONTRACT=$LAYER_ZERO_DEST_CONTRACT

# echo "Getting estimated LayerZero fee for giggles"
# LZ_SOURCE_CONTRACT=$LAYER_ZERO_SOURCE_CONTRACT LZ_DEST_CHAIN_ID=$ETH_GOERLI_LZ_CHAIN_ID MOCK_PRICE=99999 forge script script/SendLayerZeroPriceMessage.s.sol:SendMessage --private-key $PRIVATE_KEY --rpc-url $OP_GOERLI_RPC_URL

# echo "Setting trusted remote for sender"
LZ_SOURCE_CONTRACT=$LAYER_ZERO_SOURCE_CONTRACT \
    LZ_DEST_CONTRACT=$LAYER_ZERO_DEST_CONTRACT \
    LZ_DEST_CHAIN_ID=$ETH_GOERLI_LZ_CHAIN_ID \
    forge script script/LayerZeroSetTrustedRemote.s.sol:SetTrustedRemote --broadcast --private-key $PRIVATE_KEY --rpc-url $OP_GOERLI_RPC_URL


# echo "Setting trusted remote for recipient"
LZ_SOURCE_CONTRACT=$LAYER_ZERO_DEST_CONTRACT \
    LZ_DEST_CONTRACT=$LAYER_ZERO_SOURCE_CONTRACT \
    LZ_DEST_CHAIN_ID=$OP_GOERLI_LZ_CHAIN_ID \
    forge script script/LayerZeroSetTrustedRemote.s.sol:SetTrustedRemote --broadcast --private-key $PRIVATE_KEY --rpc-url $ETH_RPC_URL


echo "Sending a message for real"
LZ_SOURCE_CONTRACT=$LAYER_ZERO_SOURCE_CONTRACT LZ_DEST_CHAIN_ID=$ETH_GOERLI_LZ_CHAIN_ID forge script script/SendLayerZeroPriceMessage.s.sol:SendMessage --broadcast --private-key $PRIVATE_KEY --rpc-url $OP_GOERLI_RPC_URL

