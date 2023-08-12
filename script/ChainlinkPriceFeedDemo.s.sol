// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {AggregatorV3Interface} from "@chainlink/v0.8/interfaces/AggregatorV3Interface.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        // vm.startBroadcast();
        // Run this with an OP Goerli RPC endpoint like https://goerli.optimism.io

        // USDC
        AggregatorV3Interface usdc = AggregatorV3Interface(0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7);
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            usdc.latestRoundData();

        AggregatorV3Interface dai = AggregatorV3Interface(0x0d79df66BE487753B02D015Fb622DED7f0E9798d);
        console.log("Dumping price");
        console.log("USDC: %s", uint256(answer));
        console.log("Make sure to select the correct decimals in the data provider, it's typically 8");
        console.log("Decimals %s", uint256(usdc.decimals()));

        (, int256 answer2,,,) = dai.latestRoundData();
        console.log("DAI: %s", uint256(answer2));
        console.log("Decimals %s", uint256(dai.decimals()));

        // vm.stopBroadcast();
    }
}
