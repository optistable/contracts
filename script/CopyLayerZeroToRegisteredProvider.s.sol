// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {GenericDataProvider} from "../src/GenericDataProvider.sol";
import {OracleCommittee} from "../src/OracleCommittee.sol";
import {LayerZeroPriceFetcher} from "../src/LayerZeroPriceFetcher.sol";
import {PolicyManager} from "../src/PolicyManager.sol";

contract WritePriceData is Script {
    function setUp() public {}

    address usdcAddress = 0x222e9a549274B796715a4af8a9BB96bC6EFCd13A;
    address usdtAddress = 0xECF58c7323C56290157675777d30A1E223db451a;
    address daiAddress = 0xC3c8f830DedF94D185250bA5ac348aC1455a0520;

    function run() public {
        vm.startBroadcast();

        address lzSource = vm.envAddress("LZ_SOURCE");
        // address target = vm.envAddress("TARGET");
        console.log("Getting data providers");
        LayerZeroPriceFetcher lzDataProvider = LayerZeroPriceFetcher(lzSource);

        PolicyManager policyManager = new PolicyManager(0xDeaDDEaDDeAdDeAdDEAdDEaddeAddEAdDEAd0001);
        uint256 policyId = policyManager.createPolicy(block.number + 10, usdcAddress, usdtAddress, 5);
        OracleCommittee committee = new OracleCommittee(
            policyManager.policyAssetSymbolBytes32(policyId),
            policyManager.policyAsset(policyId),
            policyManager.policyBlock(policyId),
            policyManager.policyBlock(policyId) + policyManager.blocksPerYear()
        );
        committee.setPolicy(address(policyManager), policyId);

        console.log("Finished creating committee, assigning committee to policy");
        policyManager.setOracleCommittee(policyId, address(committee));
        address dpAddress = committee.addNewProvider(
            bytes32("layer-zero-test"), //_oracleType
            5, //_depegTolerance
            5, //_minBlocksToSwitchStatus
            8, //_decimals
            true //_isOnChain);
        );
        GenericDataProvider dataProvider = GenericDataProvider(dpAddress);
        console.log("Getting Pprice data");
        uint256 lastBlock = lzDataProvider.lastObservedBlockNumber();
        uint256 lastPrice = lzDataProvider.lastObservedPrice();
        // OracleCommittee committee = OracleCommittee(dataProvider.getOracleCommittee());
        console.log("Writing to data provider %s", address(dataProvider));
        console.log("Committee: %s", dataProvider.getOracleCommittee());
        console.log("Block: %s", block.number);
        console.log("Block: %s", dataProvider.lastBlockNum());
        console.log("Last block %s", committee.endingBlock());
        try committee.recordPriceForProvider(address(dataProvider), lastBlock, lastPrice) {
            console.log("Success");
        } catch Error(string memory reason) {
            console.log("Failed: %s", reason);
        }

        vm.stopBroadcast();
    }
}
