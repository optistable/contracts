// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Test.sol";
import "../src/Policy.sol";
import "../src/GenericDataProvider.sol";
import "../src/OracleCommittee.sol";
import "../src/tokens/MockStable.sol";

contract PolicyTest is Test {
    MockStable public stableInsuredContract;
    MockStable public stableInsurerContract;
    address public stableInsured;
    address public stableInsurer;
    address public owner = address(50);
    Policy public policy;
    address public systemAddress = address(0xDeaDDEaDDeAdDeAdDEAdDEaddeAddEAdDEAd0001);

    event PolicyCreated(
        uint256 indexed policyId, uint256 indexed blockNumber, address indexed currencyInsured, address currencyInsurer
    );

    function setUp() public {
        vm.prank(owner);
        policy = new Policy(systemAddress);
        setUpStablecoins();
    }

    function setUpStablecoins() public {
        stableInsuredContract = new MockStable();
        stableInsured = address(stableInsuredContract);
        stableInsurerContract = new MockStable();
        stableInsurer = address(stableInsurerContract);
    }

    function test_CreateOracleCommittee() public {
        console.log("starting test");
        vm.startPrank(owner);
        console.log("creating policy");
        policy.createPolicy(block.number, stableInsured, stableInsurer, 5); //TODO committee address is blank
        vm.stopPrank();
        vm.startPrank(systemAddress);

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
        assertEq(committee.minProvidersForQuorum(), 1);
        committee.addNewProvider(
            bytes32("redstone-data-feed"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );
        assertEq(committee.minProvidersForQuorum(), 1);
        committee.addNewProvider(
            bytes32("coingecko-data-feed"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus8
            8, //_decimals
            false //_isOnChain);
        );
        assertEq(committee.minProvidersForQuorum(), 2);
        vm.stopPrank();
    }
}
