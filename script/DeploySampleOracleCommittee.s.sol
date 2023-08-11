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
        address systemAddress = vm.envAddress("SYSTEM_ADDRESS");

        Policy policy = new Policy(systemAddress);
        policy.createPolicy(block.number, address(1), address(0), 5); //TODO committee address is blank

        OracleCommittee committee = new OracleCommittee(
            address(policy),
            bytes32("USDC"), //_symbol,
            address(1), //_l1TokenAddress
            block.number, //_startingBlock,
            block.number + 1001 //_endingBlock,
        );

        committee.addNewProvider(
            bytes32("chainlink-data-feed"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );
        committee.addNewProvider(
            bytes32("chainlink-ccip-data-feed"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );
        committee.addNewProvider(
            bytes32("covalent-data-feed"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            false //_isOnChain);
        );

        vm.stopBroadcast();
    }
}
