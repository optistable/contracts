// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {ChainlinkPriceFeedDataProvider} from "../src/ChainlinkPriceFeedDataProvider.sol";
import {OracleCommittee} from "../src/OracleCommittee.sol";
import {Policy} from "../src/Policy.sol";

contract ContractScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        // solhint-disable-next-line
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        // Sepolia feeds here: https://docs.chain.link/data-feeds/price-feeds/addresses#Sepolia%20Testnet
        ChainlinkPriceFeedDataProvider usdcFeed = new ChainlinkPriceFeedDataProvider(
                0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E, //l1 feed address
                0xfF665907206Ccdc397BAe7E2638C5ecFa7436B4E, //_systemAddress
                bytes32("USDC"),
                5, //depegTolerance
                5, //_minBlocksToSwitchStatus
                8 //decimals
            );
        // console.log(usdcFeed.getSystemAddress());
        // // console.log(usdcFeed.getSymbol());
        // console.log(usdcFeed.getFeedAddress());
        // ChainlinkPriceFeedDataProvider daiFeed = new ChainlinkPriceFeedDataProvider(
        //         0x14866185B1962B63C3Ea9E03Bc1da838bab34C19,
        //         0xfF665907206Ccdc397BAe7E2638C5ecFa7436B4E, //_systemAddress
        //         bytes32("DAI"), //_symbol
        //         5, //depegTolerance
        //         5, //_minBlocksToSwitchStatus
        //         8 //decimals
        //     );

        // daiFeed.setSystemAddress(0xfF665907206Ccdc397BAe7E2638C5ecFa7436B4E);
        // console.log(daiFeed.getSystemAddress());
        // // console.log(daiFeed.getSymbol());
        // console.log(daiFeed.getFeedAddress());

        address[] memory providers;
        providers[0] = address(usdcFeed);
        Policy policy = new Policy();
        policy.createPolicy(block.number, address(1), address(0)); //TODO committee address is blank
        OracleCommittee committee = new OracleCommittee(
        address(0),
        1, //_minProvidersForQuorum,
        block.number, //_startingBlock,
        block.number + 20, //_endingBlock,
    providers
    );
        usdcFeed.setOracleCommittee(address(committee));

        vm.stopBroadcast();
    }
}
