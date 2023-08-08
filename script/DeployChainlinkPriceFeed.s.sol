// // SPDX-License-Identifier: MIT
// pragma solidity =0.8.21;

// import "forge-std/Script.sol";
// import "forge-std/console.sol";

// import {ChainlinkPriceFeedDataProvider} from "../src/ChainlinkPriceFeedDataProvider.sol";
// import {OracleCommittee} from "../src/OracleCommittee.sol";

// contract ContractScript is Script {
//     function setUp() public {}

//     function run() public {
//         vm.startBroadcast();
//         // solhint-disable-next-line
//         uint256 deployerKey = vm.envUint("PRIVATE_KEY");

//         address _feed,
//         address _systemAddress, // The address authorized to record prices
//         address _committeeAddress, // The address where central config comes from
//         bytes32 _symbol,
//         uint256 _depegTolerance,
//         uint8 _minBlocksToSwitchStatus,
//         uint8 _decimals

//         // Sepolia feeds here: https://docs.chain.link/data-feeds/price-feeds/addresses#Sepolia%20Testnet
//         ChainlinkPriceFeedDataProvider usdcFeed = new ChainlinkPriceFeedDataProvider(
//                 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E, //l1 feed address
// 0xfF665907206Ccdc397BAe7E2638C5ecFa7436B4E, //_systemAddress
// address(0), //oracleCommittee
//                 bytes32("USDC"),
//                 5, //depegTolerance
//                 5, //_minBlocksToSwitchStatus
//                 8 //decimals
//             );
//         usdcFeed.setSystemAddress();
//         console.log(usdcFeed.getSystemAddress());
//         // console.log(usdcFeed.getSymbol());
//         console.log(usdcFeed.getFeedAddress());
//         ChainlinkPriceFeedDataProvider daiFeed = new ChainlinkPriceFeedDataProvider(
//                 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19,
//                 0xfF665907206Ccdc397BAe7E2638C5ecFa7436B4E, //_systemAddress
//                 address(0), //oracleCommittee
//                 bytes32("USDC"),
//                 5, //depegTolerance
//                 5, //_minBlocksToSwitchStatus
//                 8 //decimals
//                 bytes32("DAI")
//             );

//         daiFeed.setSystemAddress(0xfF665907206Ccdc397BAe7E2638C5ecFa7436B4E);
//         console.log(daiFeed.getSystemAddress());
//         // console.log(daiFeed.getSymbol());
//         console.log(daiFeed.getFeedAddress());
//         vm.stopBroadcast();
//     }
// }
