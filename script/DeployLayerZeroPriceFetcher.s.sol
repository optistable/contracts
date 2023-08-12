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

contract Deploy is Script {
    struct LzMeta {
        uint16 lzChainId;
        address lzEndpoint;
        address usdcPriceFeed;
        address usdtPriceFeed;
        address daiPriceFeed;
    }

    mapping(uint256 => LzMeta) chainIdToLzChainId;

    function setUp() public {
        chainIdToLzChainId[5] = LzMeta({ // Goerli
            lzChainId: 10121,
            lzEndpoint: 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23,
            usdcPriceFeed: 0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7,
            usdtPriceFeed: address(0), //Doesn't exist. This is a killer feature of the LZ impl, making the USDT price feed data available on ETH goerli
            daiPriceFeed: 0x0d79df66BE487753B02D015Fb622DED7f0E9798d
        });

        chainIdToLzChainId[420] = LzMeta({ // OP Goerli
            lzChainId: 10132,
            lzEndpoint: 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1,
            usdcPriceFeed: 0x2636B223652d388721A0ED2861792DA9062D8C73,
            usdtPriceFeed: 0x2e2147bCd571CE816382485E59Cd145A2b7CA451,
            daiPriceFeed: 0x31856c9a2A73aAee6100Aed852650f75c5F539D0
        });

        chainIdToLzChainId[80001] = LzMeta({ // Mumbai
            lzChainId: 10109,
            lzEndpoint: 0xf69186dfBa60DdB133E91E9A4B5673624293d8F8,
            usdcPriceFeed: 0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0,
            usdtPriceFeed: 0x92C09849638959196E976289418e5973CC96d645,
            daiPriceFeed: 0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046
        });
    }

    function run() public {
        vm.startBroadcast();

        string memory symbol = vm.envString("SYMBOL"); //USDC, USDT, DAI
        uint16 lzSourceChainId = uint16(vm.envOr("LZ_SOURCE_CHAIN_ID", uint256(0))); //You probably want 10109 for ETH mumbai or 10132 for OP goerli
        address lzSourceContract = vm.envOr("LZ_SOURCE_CONTRACT", address(0)); //The address of the source contract on the source chain
        bool isDestDeployment = vm.envBool("IS_DEST_DEPLOYMENT"); //Set to true if you are deploying to the destination chain, false if you are deploying to the source chain
        address existingDataProviderRecipient = vm.envOr("DATA_PROVIDER_ADDRESS", address(0)); // TODO wire this in

        address priceFeedAddress = address(0);
        LzMeta memory meta = chainIdToLzChainId[block.chainid];

        // We only need to set up the price feeds on the source contract
        if (!isDestDeployment) {
            require(meta.lzChainId != 0, "Unsupported chain");
            lzSourceChainId = meta.lzChainId;

            if (keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("USDC"))) {
                priceFeedAddress = meta.usdcPriceFeed;
            } else if (keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("USDT"))) {
                priceFeedAddress = meta.usdtPriceFeed;
            } else if (keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("DAI"))) {
                priceFeedAddress = meta.daiPriceFeed;
            } else {
                revert("Unsupported symbol");
            }
        }

        // TODO Last param is a data provider to send the data to
        console.log("LzEndpoint: %s, %s, %s", meta.lzEndpoint);
        LayerZeroPriceFetcher lzPriceFetcher = new LayerZeroPriceFetcher(meta.lzEndpoint,priceFeedAddress,address(0));

        if (isDestDeployment) {
            console.log("source chain id is... %s", lzSourceChainId);
            //If deployment target is not polygon, this contract should be set up to receive messages
            require(
                lzSourceChainId == 10121 || lzSourceChainId == 10132 || lzSourceChainId == 10109,
                "Unsupported dest chain id (set LZ_DEST_CHAIN_ID env var)"
            );
            // is the below require actually necessary. Could I do an lz message on the same chain?
            require(
                chainIdToLzChainId[block.chainid].lzChainId != lzSourceChainId,
                "Source and dest chain ids must be different"
            );
            require(lzSourceContract != address(0), "Unsupported dest contract address (set LZ_DEST_CONTRACT env var)");
            // uint160 u160rep = uint160(lzSourceContract);
            // lzPriceFetcher.setTrustedRemoteAddress(lzSourceChainId, abi.encode(lzSourceContract));
            lzPriceFetcher.setTrustedRemoteAddress(lzSourceChainId, abi.encodePacked(lzSourceContract));
            // lzPriceFetcher.setTrustedRemoteAddress(lzSourceChainId, abi.encodePacked(lzSourceContract));

            // Send a message from the source contract
            // LayerZeroPriceFetcher source = LayerZeroPriceFetcher(lzSourceContract);
            // source.sendPriceMessage(chainIdToLzChainId[block.chainId].lzChainId);
        }
        vm.stopBroadcast();
        // vm.startBroadcast();

        // // policy.createPolicy(block.number, address(1), address(0), 5); //TODO committee address is blank
        // // USDC -> DAI on Goerli
        // policy.createPolicy(
        //     block.number, 0x222e9a549274B796715a4af8a9BB96bC6EFCd13A, 0xC3c8f830DedF94D185250bA5ac348aC1455a0520, 5
        // ); //TODO committee address is blank

        // OracleCommittee committee = new OracleCommittee(
        //     address(policy),
        //     bytes32("USDC"), //_symbol,
        //     address(1), //_l1TokenAddress
        //     block.number + 10, //_startingBlock,
        //     block.number + 1001 //_endingBlock,
        // );

        // committee.addNewProvider(
        //     bytes32("chainlink-data-feed"), //_oracleType
        //     5, //_depegTolerance
        //     5, //_minBlocksToSwitchStatus
        //     8, //_decimals
        //     true //_isOnChain);
        // );
        // committee.addNewProvider(
        //     bytes32("chainlink-ccip-data-feed"), //_oracleType
        //     5, //_depegTolerance
        //     5, //_minBlocksToSwitchStatus
        //     8, //_decimals
        //     true //_isOnChain);
        // );
        // committee.addNewProvider(
        //     bytes32("covalent-data-feed"), //_oracleType
        //     5, //_depegTolerance
        //     5, //_minBlocksToSwitchStatus
        //     8, //_decimals
        //     false //_isOnChain);
        // );

        // vm.stopBroadcast();
    }
}
