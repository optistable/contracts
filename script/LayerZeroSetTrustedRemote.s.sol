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

contract SetTrustedRemote is Script {
    mapping(uint256 => uint16) chainIdToLzChainId;

    function setUp() public {
        chainIdToLzChainId[5] = 10121;
        chainIdToLzChainId[420] = 10132;
        chainIdToLzChainId[80001] = 10109;
    }

    function run() public {
        vm.startBroadcast();
        address lzSourceContract = vm.envAddress("LZ_SOURCE_CONTRACT"); //The address of the source contract on the source chain
        uint16 lzSourceChainId = chainIdToLzChainId[block.chainid]; //TODO this shouldn't be necessary
        address lzDestContract = vm.envAddress("LZ_DEST_CONTRACT"); //The address of the source contract on the source chain
        uint16 lzDestChainId = uint16(vm.envUint("LZ_DEST_CHAIN_ID")); //The address of the source contract on the source chain

        console.log("Setting up remote trust addresses from %s to %s", chainIdToLzChainId[block.chainid], lzDestChainId);
        LayerZeroPriceFetcher lzPriceFetcher = LayerZeroPriceFetcher(lzSourceContract);
        // bytes memory path = lzPriceFetcher.getTrustedRemoteAddress(lzDestChainId);
        // if (path.length != 0 && path == abi.encodePacked(lzSourceContract, lzDestContract)) {
        //     console.log("Contract already trusted");
        //     return;
        // }

        lzPriceFetcher.setTrustedRemoteAddress(lzDestChainId, abi.encodePacked(lzDestContract));
        // lzPriceFetcher.setTrustedRemote(lzDestChainId, abi.encodePacked(lzSourceContract, lzDestContract)); //TODO Shouldn't be necessary, clone of above
        // console.log("path len", abi.encodePacked(lzSourceContract, lzDestContract).length);
        // lzPriceFetcher.setTrustedRemoteAddress(lzSourceChainId, abi.encodePacked(lzDestContract)); //TODO shouldn't be necessary
        // lzPriceFetcher.setTrustedRemoteAddress(lzSourceChainId, abi.encodePacked(lzDestContract));
        vm.stopBroadcast();
    }
}
