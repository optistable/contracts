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
            block.number+1, //_startingBlock,
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

        address[] memory providers = committee.getProviders();
        for (uint256 i = 0; i < providers.length; i++) {
            console.log("provider: %s", providers[i]);
        }
        GenericDataProvider provider1 = GenericDataProvider(providers[0]);
        GenericDataProvider provider2 = GenericDataProvider(providers[1]);
        GenericDataProvider provider3 = GenericDataProvider(providers[2]);
        uint256 depegPrice = provider1.stableValue() - provider1.depegTolerance();
        console.log("depegPrice: %s", depegPrice);
        console.log("stableValue: %s", provider1.stableValue());
        console.log("depegTolerance: %s", provider1.depegTolerance());
        console.log("endingBlock: %s", committee.endingBlock());
        console.log("startingBlock: %s", committee.startingBlock());
        console.log("block.number: %s", block.number);
        provider1.recordPrice(block.number, depegPrice + 1);
        assertEq(provider1.lastObservation(), depegPrice + 1);
        assertEq(provider1.lastBlockNum(), block.number);
        assertEq(provider1.lastObservationDepegged(), false);

        vm.expectRevert();
        provider1.recordPrice(block.number, depegPrice + 1);

        for (uint8 i = 0; i < provider1.minBlocksToSwitchStatus(); i++) {
            vm.roll(i + 2);
            provider1.recordPrice(block.number, depegPrice);
            assertEq(provider1.lastObservation(), depegPrice);
            assertEq(provider1.lastBlockNum(), block.number);
            assertEq(provider1.lastObservationDepegged(), true);
            assertEq(provider1.switchStatusCounter(), i + 1);
        }
        assertEq(provider1.depegged(), true);
        assertEq(committee.isDepegged(), false);

        for (uint8 i = 0; i < provider2.minBlocksToSwitchStatus(); i++) {
            vm.roll(i + 2);
            provider2.recordPrice(block.number, depegPrice);
            assertEq(provider2.lastObservation(), depegPrice);
            assertEq(provider2.lastBlockNum(), block.number);
            assertEq(provider2.lastObservationDepegged(), true);
            assertEq(provider2.switchStatusCounter(), i + 1);
        }
        assertEq(provider2.depegged(), true);
        console.log("provider2 depegged: %s", provider2.depegged());

        assertEq(committee.isDepegged(), true);
        vm.stopPrank();
    }
}
