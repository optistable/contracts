/// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Script.sol";
import "src/Policy.sol";

contract DeployPolicy is Script {
    Policy public policy;

    function run() public {
        vm.startBroadcast();

        // policy = new Policy(0xDeaDDEaDDeAdDeAdDEAdDEaddeAddEAdDEAd0001);
        policy = new Policy();

        vm.stopBroadcast();
    }
}
