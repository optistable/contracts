// // SPDX-License-Identifier: MIT
// pragma solidity =0.8.21;

// import "forge-std/Test.sol";
// import "../src/Policy.sol";
// import "../src/GenericDataProvider.sol";
// import "../src/OracleCommittee.sol";
// import "../src/mocks/MockStable.sol";

// contract PolicyTest is Test {
//     MockStable public stableInsuredContract;
//     MockStable public stableInsurerContract;
//     address public stableInsured;
//     address public stableInsurer;
//     // address public owner = address(50);
//     address public owner = address(0x9cbC225B9d08502d231a6d8c8FF0Cc66aDcc2A4F);
//     Policy public policy;
//     address public systemAddress = address(0x9cbC225B9d08502d231a6d8c8FF0Cc66aDcc2A4F);
//     // address public systemAddress = address(0xDeaDDEaDDeAdDeAdDEAdDEaddeAddEAdDEAd0001);

//     event PolicyCreated(
//         uint256 indexed policyId, uint256 indexed blockNumber, address indexed currencyInsured, address currencyInsurer
//     );

//     function setUp() public {
//         vm.prank(owner);
//         policy = new Policy();
//         setUpStablecoins();
//     }

//     function setUpStablecoins() public {
//         stableInsuredContract = new MockStable();
//         stableInsured = address(stableInsuredContract);
//         stableInsurerContract = new MockStable();
//         stableInsurer = address(stableInsurerContract);
//     }

//     function test_CreateOracleCommittee() public {
//         console.log("starting test");
//         vm.startPrank(owner);
//         console.log("creating policy");
//         uint256 policyId = policy.createPolicy(block.number + 1, stableInsured, stableInsurer, 5); //TODO committee address is blank

//         console.log("finished creating policy");
//         OracleCommittee committee = policy.policyOracleCommittee(policyId);
//         console.log("committee address: %s", address(committee));
//         policy.addNewProviderToCommittee(
//             policyId,
//             bytes32("chainlink-data-feed"), //_oracleType
//             5, //_depegTolerance
//             5, //_minBlocksToSwitchStatus
//             8, //_decimals
//             true //_isOnChain);
//         );
//         assertEq(committee.minProvidersForQuorum(), 1);
//         policy.addNewProviderToCommittee(
//             policyId,
//             bytes32("redstone-data-feed"), //_oracleType
//             5, //_depegTolerance
//             5, //_minBlocksToSwitchStatus
//             8, //_decimals
//             true //_isOnChain);
//         );
//         assertEq(committee.minProvidersForQuorum(), 1);
//         policy.addNewProviderToCommittee(
//             policyId,
//             bytes32("coingecko-data-feed"), //_oracleType
//             5, //_depegTolerance
//             5, //_minBlocksToSwitchStatus8
//             8, //_decimals
//             false //_isOnChain);
//         );
//         assertEq(committee.minProvidersForQuorum(), 2);

//         GenericDataProvider provider1 = GenericDataProvider(committee.providers(0));
//         GenericDataProvider provider2 = GenericDataProvider(committee.providers(1));
//         GenericDataProvider provider3 = GenericDataProvider(committee.providers(2));
//         uint256 depegPrice = provider1.stableValue() - provider1.depegTolerance();
//         console.log("depegPrice: %s", depegPrice);
//         console.log("stableValue: %s", provider1.stableValue());
//         console.log("depegTolerance: %s", provider1.depegTolerance());
//         console.log("endingBlock: %s", committee.endingBlock());
//         console.log("startingBlock: %s", committee.startingBlock());
//         console.log("block.number: %s", block.number);

//         // policy.recordPriceForCommittee(policyId, address(provider1), block.number, depegPrice + 1);
//         // assertEq(provider1.lastObservation(), depegPrice + 1);
//         // assertEq(provider1.lastBlockNum(), block.number);
//         // assertEq(provider1.lastObservationDepegged(), false);
//         // console.log("Finished smoke test");

//         // vm.expectRevert();
//         // policy.recordPriceForCommittee(policyId, address(provider1), block.number, depegPrice + 1);

//         // for (uint8 i = 0; i < provider1.minBlocksToSwitchStatus(); i++) {
//         //     vm.roll(i + 2);
//         //     policy.recordPriceForCommittee(policyId, address(provider1), block.number, depegPrice);
//         //     assertEq(provider1.lastObservation(), depegPrice);
//         //     assertEq(provider1.lastBlockNum(), block.number);
//         //     assertEq(provider1.lastObservationDepegged(), true);
//         //     assertEq(provider1.switchStatusCounter(), i + 1);
//         // }
//         // assertEq(provider1.depegged(), true);
//         // assertEq(committee.isDepegged(), false);

//         // for (uint8 i = 0; i < provider2.minBlocksToSwitchStatus(); i++) {
//         //     vm.roll(i + 2);
//         //     policy.recordPriceForCommittee(policyId, address(provider2), block.number, depegPrice);
//         //     assertEq(provider2.lastObservation(), depegPrice);
//         //     assertEq(provider2.lastBlockNum(), block.number);
//         //     assertEq(provider2.lastObservationDepegged(), true);
//         //     assertEq(provider2.switchStatusCounter(), i + 1);
//         // }
//         // console.log("checking if provider 2 depegged");
//         // assertEq(provider2.depegged(), true);
//         // console.log("provider2 depegged: %s", provider2.depegged());

//         // assertEq(committee.isDepegged(), true);
//         vm.stopPrank();
//     }
// }
