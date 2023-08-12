// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {GenericDataProvider} from "../src/GenericDataProvider.sol";
import {LayerZeroPriceFetcher} from "../src/LayerZeroPriceFetcher.sol";

/*
Real chain ids:
    OP Goerli: 420
    Goerli: 5
    Polygon Mumbai: 80001

LayerZero endpoints (lz chain id, lz endpoint):
    Eth Goerli: 10121, 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23
    OP Goerli: 10132, 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1
    Polygon Mumbai: 10109 0xf69186dfBa60DdB133E91E9A4B5673624293d8F8
    
Chainlink price feeds:
    Mumbai USDC: 0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0
    Mumbai USDT: 0x92C09849638959196E976289418e5973CC96d645
    Mumbai DAI: 0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046

*/

contract SendMessage is Script {
    mapping(uint256 => uint16) chainIdToLzChainId;

    function setUp() public {
        chainIdToLzChainId[5] = 10121;
        chainIdToLzChainId[420] = 10132;
        chainIdToLzChainId[80001] = 10109;
    }

    function run() public {
        vm.startBroadcast();

        address lzSourceContract = vm.envAddress("LZ_SOURCE_CONTRACT"); //The address of the source contract on the source chain
        uint16 lzDestChainId = uint16(vm.envUint("LZ_DEST_CHAIN_ID")); //The address of the source contract on the source chain
        int256 mockPrice = vm.envOr("MOCK_PRICE", int256(0)); //If set will call estimateFee
        bool useZro = vm.envOr("USE_ZRO", true); //If set will call estimateFee

        // We only need to set up the price feeds on the source contract
        // TODO Last param is a data provider to send the data to
        LayerZeroPriceFetcher lzPriceFetcher = LayerZeroPriceFetcher(lzSourceContract);

        console.log("Sending a real price feed to %s from %s", lzDestChainId, chainIdToLzChainId[block.chainid]);
        bytes memory path = lzPriceFetcher.getTrustedRemoteAddress(lzDestChainId);
        require(path.length != 0, "LzApp: no trusted path record");

        if (mockPrice != 0) {
            console.log("Preparing to get estimateFee %s", lzDestChainId);
            console.log("Mock price %s", uint256(mockPrice));
            console.log("Source contract %s", lzSourceContract);
            (uint256 nativeFee, uint256 zroFee) = lzPriceFetcher.estimateFee(lzDestChainId, useZro, mockPrice);
            console.log("Native fee %s", nativeFee);
            console.log("Zro fee %s", zroFee);
        } else {
            (uint256 nativeFee, uint256 zroFee) = lzPriceFetcher.estimateFee(lzDestChainId, useZro, 100000000);
            console.log("Native fee %s", nativeFee);
            console.log("Zro fee %s", zroFee);
            console.log("Sending a real price feed to %s from %s", lzDestChainId, chainIdToLzChainId[block.chainid]);
            lzPriceFetcher.sendPriceData{value: nativeFee + 0.0001 ether}(lzDestChainId);
        }

        vm.stopBroadcast();
    }
}
