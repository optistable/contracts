// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {GenericDataProvider} from "../src/GenericDataProvider.sol";
import {Policy} from "../src/Policy.sol";

contract Deploy is Script {
    function setUp() public {

    }

    function run() public {
        vm.startBroadcast();
        address systemAddress = vm.envAddress("SYSTEM_ADDRESS");
        Policy policy = new Policy(systemAddress);
        vm.stopBroadcast();
    }
}
