#!/bin/bash

chainlink_data_feeds=("0x385c3849a65F9824E16969186f2B7A1ffaB80ADD" "0x4850971A47537F40F80a6DAfAeC6f81EF054eEFc" "0xC525c036d8d435622D940F31B618b307547752aC" "0xd4baCFe205a4Bc6bE6c1C5f736FD5f8e59126D96" "0x66528c190F9a75F1805bF9AB16C6504FD3304e2a")

PRICE=$(forge script script/ChainlinkPriceFeedDemo.s.sol:Deploy --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY | grep "PRICE:" | awk '{print $NF}')
echo "Read price from chainlink: $PRICE"
for address in "${chainlink_data_feeds[@]}"
do 
  echo "Chainlink Data Feed: $address"
    TARGET=$address PRICE=$PRICE forge script script/WriteToProvider.s.sol:WritePriceData --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY -vv
done




# chainlink_ccip=("0x76c890BFc5fa9ffDd5431B1D13B3508925Ee0EE3",
# "0x65Aa9c22f30f6236f12E01C1EC78274Bc8e121a4",
# "0xE53327859Daa78A197734DCFB87dd5ADb35CBBDe",
# "0x31E4fe48aEA19C708898B3A6B689307BA4fFbC10",
# "0xfAa232B98334477D544c283A2011B50FA6D847eE",
# "0x2CCb287F30D294187b3Ec1759538A691F03d3a18")

redstone_data_feeds=("0xadcddEeD2DCd355ECA74D57cb1346345E1616136" "0x1205C8608bdbd754064779C75D4E7f070A2caF99" "0x08909E9b7f48768E6eBd213a0C3B1A6a432D7383" "0x2b72FA4Cc6060Fa5750c1Ec560CD2e370192F78D" "0x6aB5db3e59eab8E597Eb5E47AC05f42e3d721b9B" "0x86D8c6c61A2B5955ad62a365D915D77ABfFa0c1C")
redstone_api_url="https://api.redstone.finance/prices/?symbol=USDC&provider=redstone&limit=1"
redstone_response=$(curl -s $redstone_api_url)
redstone_usdc_price=$(echo $redstone_response | jq -r '.[0].value')
echo "Read price from redstone: $redstone_usdc_price"
redstone_usdc_uint=$(echo "$redstone_usdc_price * 100000000" | bc)
redstone_rounded_value=$(printf "%.0f" "$redstone_usdc_uint")
echo "Rounded price from redstone: $redstone_rounded_value"
for address in "${redstone_data_feeds[@]}"
do 
  echo "Redstone data feed: $address"
  TARGET=$address PRICE=$redstone_rounded_value forge script script/WriteToProvider.s.sol:WritePriceData --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY -vv
ß# done

layer_zero_op_goerli=("0xAb09bA4f6E58920Bd8085eEf175E48cFd6aB7d8b" "0x17908de72A6B1db522edDB07Ea52ba5BA385b7D2" "0x9122F65886ef89E5eBE325c0Dd72940ACcE64fF6" "0x66b567603383C38a389d9AcEe73a701a0963333B" "0x68d039F984fe230A21814c9A85F06e191E7Fa25c" "0x06D7e357986B6e94adfC7cA005E1654F668658c2")

# Layer zero is weird. you initialize a transaction on OP Goerli, then just wait for your sepolia contract to update
# Since this runs every 5m, I'm not waiting. Send the message and move on
OP_GOERLI_LZ_CHAIN_ID=10132 # Sender chain
ETH_GOERLI_LZ_CHAIN_ID=10121 # Recipient chain
LAYER_ZERO_SOURCE_CONTRACT=0x580e79C5797B66101C248f8eaD0cC3f5a7d59b33
LAYER_ZERO_DEST_CONTRACT=0x6B94C911FAcC7f3c360ECA1c78bF672BE7CC487B
echo "sending LayerZero message to trigger price update for next round"
LZ_SOURCE_CONTRACT=$LAYER_ZERO_SOURCE_CONTRACT LZ_DEST_CHAIN_ID=$ETH_GOERLI_LZ_CHAIN_ID forge script script/SendLayerZeroPriceMessage.s.sol:SendMessage --broadcast --private-key $PRIVATE_KEY --rpc-url $OP_GOERLI_RPC_URL
for address in "${layer_zero_op_goerli[@]}"
do
#     # Naming below is weird. The source of LZ price data is on the same chain as the destination of the price data. The origin of the price data is from the source chain.
#     echo "Layer Zero data feed: $address"
    # LZ_SOURCE=$LAYER_ZERO_DEST_CONTRACT TARGET=$address forge script script/WriteToProvider.s.sol:WritePriceData --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_GOERLI_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY -vv
    LZ_SOURCE=$LAYER_ZERO_DEST_CONTRACT TARGET=$address forge script script/CopyLayerZeroToRegisteredProvider.s.sol:WritePriceData --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL -vv
done


echo "Sending a message for real"

done


coingecko=("0xD58Fc8d8bB912bFbE8a9e347f1B36b1cE21E9F80" "0x8B33bfF4C46Ea6FEE193EE975A712b742e54857e" "0x7B99Edac2D93c3975Fa164015714CeCf73C8793A" "0xe0350E2a6FC34bE28747d77D22E32b6678abCdda" "0xbea4923f19CE3aD74c7824B1EE9B6761d6092Eee" "0x690530f8799CEa1F506dF253d54b9c31dd65FFB3")
api_url="https://api.coingecko.com/api/v3/simple/price?ids=tether&vs_currencies=usd"
response=$(curl -s "$api_url")
coingecko_usdt_price=$(echo "$response" | jq -r '.tether.usd')


coingeck_usdt_uint=$(echo "$coingecko_usdt_price * 100000000" | bc)
rounded_value=$(printf "%.0f" "$coingeck_usdt_uint")
# Print the USDT price
# echo "Current USDT Price: $coingecko_usdt_price USD whole number: $rounded_value"
for address in "${coingecko[@]}"
do 
  echo "CoinGecko data feed: $address"
  TARGET=$address PRICE=$rounded_value forge script script/WriteToProvider.s.sol:WritePriceData --private-key $PRIVATE_KEY --broadcast --rpc-url $ETH_RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY -vv
done
