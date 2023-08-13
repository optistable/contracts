// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {GenericDataProvider} from "../src/GenericDataProvider.sol";
import {OracleCommittee} from "../src/OracleCommittee.sol";
import {IOracleCommittee} from "../src/interfaces/IOracleCommittee.sol";
import {PolicyManager} from "../src/PolicyManager.sol";

contract Deploy is Script {
    function setUp() public {}

    address usdcAddress = 0x222e9a549274B796715a4af8a9BB96bC6EFCd13A;
    address usdtAddress = 0xECF58c7323C56290157675777d30A1E223db451a;
    address daiAddress = 0xC3c8f830DedF94D185250bA5ac348aC1455a0520;
    PolicyManager policyManager;

    function createAllVariationsOfPolicies(uint256 _blockNumber) public returns (uint256[] memory) {
        uint256[] memory result = new uint256[](6);
        console.log("Creating usdc/usdt policy");
        result[0] = policyManager.createPolicy(_blockNumber, usdcAddress, usdtAddress, 5);
        console.log("Creating usdc/dai policy");
        result[1] = policyManager.createPolicy(_blockNumber + 1000, usdcAddress, daiAddress, 5);
        console.log("Creating usdt/usdc policy");
        result[2] = policyManager.createPolicy(_blockNumber + 1000, usdtAddress, usdcAddress, 5);
        console.log("Creating usdt/dai policy");
        result[3] = policyManager.createPolicy(_blockNumber, usdtAddress, daiAddress, 5);
        console.log("Creating dai/usdc policy");
        result[4] = policyManager.createPolicy(_blockNumber, daiAddress, usdcAddress, 5);
        console.log("Creating dai/usdt policy");
        result[5] = policyManager.createPolicy(_blockNumber + 1000, daiAddress, usdtAddress, 5);
        console.log("Finished creating policies");
        return result;
    }

    function assignPolicyToOracleCommittee(uint256 policyId) public {
        OracleCommittee committee = new OracleCommittee(
            policyManager.policyAssetSymbolBytes32(policyId),
            policyManager.policyAsset(policyId),
            policyManager.policyBlock(policyId),
            policyManager.policyBlock(policyId) + policyManager.blocksPerYear()
        );
        committee.setPolicy(address(policyManager), policyId);
        console.log("Finished creating committee, assigning committee to policy");
        policyManager.setOracleCommittee(policyId, address(committee));
        policyManager.addNewProviderToCommittee(
            policyId,
            bytes32("chainlink-data-feed"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );
        policyManager.addNewProviderToCommittee(
            policyId,
            bytes32("chainlink-ccip-base"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );
        policyManager.addNewProviderToCommittee(
            policyId,
            bytes32("redstone-data-feed"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );

        policyManager.addNewProviderToCommittee(
            policyId,
            bytes32("layer-zero-op-goerli"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );

        policyManager.addNewProviderToCommittee(
            policyId,
            bytes32("coingecko"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );
    }

    function run() public {
        vm.startBroadcast();
        console.log("Creating policy");
        policyManager = new PolicyManager(msg.sender);
        console.log("Policy: %s", address(policyManager));
        uint256[] memory policies = createAllVariationsOfPolicies(block.number + 20); //start block, put forward so we can get transactions in
        for (uint256 i = 0; i < policies.length; i++) {
            assignPolicyToOracleCommittee(policies[i]);
            console.log("--------Policy ID %s---------", policies[i]);
            console.log("Policy: ", policies[i]);
            IOracleCommittee committee = policyManager.policyOracleCommittee(policies[i]);
            console.log("Committee: ", address(committee));
            address[] memory providers = committee.getProviders();
            for (uint256 j = 0; j < providers.length; j++) {
                console.log("Provider: ", providers[j]);
            }
            console.log("-----------------------------");
        }
        vm.stopBroadcast();
    }
}
