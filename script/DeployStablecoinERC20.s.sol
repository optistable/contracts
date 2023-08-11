// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../src/EverythingBurns.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        EverythingBurns usdc = new EverythingBurns("OptiStable USDC", "USDC");
        EverythingBurns usdt = new EverythingBurns("OptiStable USDT", "USDT");
        EverythingBurns dai = new EverythingBurns("OptiStable DAI", "DAI");

        address[] memory addressesToMintTo = new address[](20);

        addressesToMintTo[0] = 0x9cbC225B9d08502d231a6d8c8FF0Cc66aDcc2A4F;

        for (uint256 i = 0; i < addressesToMintTo.length; i++) {
            if (addressesToMintTo[i] == address(0)) {
                continue;
            }
            usdc.mint(addressesToMintTo[i], 1000000000000000000000000);
            usdt.mint(addressesToMintTo[i], 1000000000000000000000000);
            dai.mint(addressesToMintTo[i], 1000000000000000000000000);
        }
        vm.stopBroadcast();
    }
}
