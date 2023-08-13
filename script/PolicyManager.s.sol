/// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Script.sol";
import "../src/PolicyManager.sol";

contract DeployPolicy is Script {
    PolicyManager public policyManager;

    function run() public {
        vm.startBroadcast();

        policyManager = new PolicyManager(0xDeaDDEaDDeAdDeAdDEAdDEaddeAddEAdDEAd0001);

        vm.stopBroadcast();
    }
}
