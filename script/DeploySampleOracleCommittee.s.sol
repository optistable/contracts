// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {GenericDataProvider} from "../src/GenericDataProvider.sol";
// import {OracleCommittee} from "../src/OracleCommittee.sol";
import {Policy} from "../src/Policy.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        address policyAddress = vm.envAddress("POLICY_ADDRESS");
        Policy policy = Policy(policyAddress);

        console.log("Creating policy");
        uint256 policyId = policy.createPolicy(
            //Addresses are optistable usdc and optistable usdt
            block.number,
            0x222e9a549274B796715a4af8a9BB96bC6EFCd13A,
            0xC3c8f830DedF94D185250bA5ac348aC1455a0520,
            5
        );
        console.log("Policy ID: %s", policyId);
        console.log("Oracle committee address: ", address(policy.policyOracleCommittee(policyId)));

        policy.addNewProviderToCommittee(
            policyId,
            bytes32("chainlink-data-feed"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );
        policy.addNewProviderToCommittee(
            policyId,
            bytes32("chainlink-ccip-base"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );
        policy.addNewProviderToCommittee(
            policyId,
            bytes32("redstone-data-feed"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );

        policy.addNewProviderToCommittee(
            policyId,
            bytes32("layer-zero-op-goerli"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );

        policy.addNewProviderToCommittee(
            policyId,
            bytes32("coingecko"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );
        vm.stopBroadcast();
    }
}
