// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {GenericDataProvider} from "../src/GenericDataProvider.sol";
import {OracleCommittee} from "../src/OracleCommittee.sol";

contract WritePriceData is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        address lzSource = vm.envAddress("LZ_SOURCE");
        address target = vm.envAddress("TARGET");
        GenericDataProvider lzDataProvider = GenericDataProvider(lzSource);
        GenericDataProvider dataProvider = GenericDataProvider(target);

        uint256 lastBlock = lzDataProvider.lastBlockNum();
        uint256 lastPrice = lzDataProvider.lastObservation();
        OracleCommittee committee = OracleCommittee(dataProvider.getOracleCommittee());
        console.log("Writing to data provider %s", target);
        console.log("Committee: %s", dataProvider.getOracleCommittee());
        console.log("Block: %s", block.number);
        console.log("Block: %s", dataProvider.lastBlockNum());
        console.log("Last block %s", committee.endingBlock());
        try committee.recordPriceForProvider(target, lastBlock, lastPrice) {
            console.log("Success");
        } catch Error(string memory reason) {
            console.log("Failed: %s", reason);
        }

        vm.stopBroadcast();
    }
}
