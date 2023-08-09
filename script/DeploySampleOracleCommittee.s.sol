// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {GenericDataProvider} from "../src/GenericDataProvider.sol";
import {OracleCommittee} from "../src/OracleCommittee.sol";
import {Policy} from "../src/Policy.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        // solhint-disable-next-line
        // uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address systemAddress = vm.envAddress("SYSTEM_ADDRESS");

        // Sepolia feeds here: https://docs.chain.link/data-feeds/price-feeds/addresses#Sepolia%20Testnet
        GenericDataProvider chainlinkFeed = new GenericDataProvider(
                bytes32("chainlink-data-feed"), //_oracleType
                systemAddress, //_systemAddress TODO change this to be owner
                address(0), //_committeeAddress (we don't know)
                bytes32("USDC"), //_symbol
                5, //_depegTolerance
                5, //_minBlocksToSwitchStatus
                8, //_decimals
                true //_isOnChain
            );

        GenericDataProvider redstoneFeed = new GenericDataProvider(
            bytes32("redstone-data-feed"), //_oracleType
            systemAddress, //_systemAddress TODO change this to be owner
            address(0), //_committeeAddress (we don't know)
            bytes32("USDC"),
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain
        );
        GenericDataProvider onlineFeed = new GenericDataProvider(
                bytes32("coingecko-data-feed"), //_oracleType
                systemAddress, //_systemAddress TODO change this to be owner
                address(0), //_committeeAddress (we don't know)
                bytes32("USDC"),
                5, //_depegTolerance
                5, //_minBlocksToSwitchStatus
                8, //_decimals
                false //_isOnChain
            );
        vm.stopBroadcast();
        vm.startBroadcast();

        address[] memory providers = new address[](3);
        // providers.push(address(chainlinkFeed));
        // providers.push(address(redstoneFeed));
        // providers.push(address(onlineFeed));
        providers[0] = address(chainlinkFeed);
        providers[1] = address(redstoneFeed);
        providers[2] = address(onlineFeed);

        Policy policy = new Policy();
        policy.createPolicy(block.number, address(1), address(0)); //TODO committee address is blank
        OracleCommittee committee = new OracleCommittee(
        address(policy),
        1, //_minProvidersForQuorum,
        block.number, //_startingBlock,
        block.number + 20, //_endingBlock,
        providers
    );
        chainlinkFeed.setOracleCommittee(address(committee));

        vm.stopBroadcast();
    }
}
