pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {ChainlinkPriceFeedDataProvider} from "src/ChainlinkPriceFeedDataProvider.sol";

import "forge-std/console.sol";

contract ContractScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        // Sepolia feeds here: https://docs.chain.link/data-feeds/price-feeds/addresses#Sepolia%20Testnet
        ChainlinkPriceFeedDataProvider usdcFeed = new ChainlinkPriceFeedDataProvider(
                0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E,
                bytes32("USDC")
            );
        usdcFeed.setSystemAddress(0xfF665907206Ccdc397BAe7E2638C5ecFa7436B4E);
        console.log(usdcFeed.getSystemAddress());
        // console.log(usdcFeed.getSymbol());
        console.log(usdcFeed.getFeedAddress());
        ChainlinkPriceFeedDataProvider daiFeed = new ChainlinkPriceFeedDataProvider(
                0x14866185B1962B63C3Ea9E03Bc1da838bab34C19,
                bytes32("DAI")
            );

        daiFeed.setSystemAddress(0xfF665907206Ccdc397BAe7E2638C5ecFa7436B4E);
        console.log(daiFeed.getSystemAddress());
        // console.log(daiFeed.getSymbol());
        console.log(daiFeed.getFeedAddress());
        vm.stopBroadcast();
    }
}
