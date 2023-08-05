// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "@redstone-finance/evm-connector/dist/contracts/data-services/MainDemoConsumerBase.sol";
// import "./IDataProvider.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// contract RedstoneDataProvider is MainDemoConsumerBase, IDataProvider, Ownable {
//     mapping(address => bytes32) public addressToBytes32;

//     function addAddressMapping(
//         address _addr,
//         bytes32 _translateTo
//     ) external onlyOwner {
//         addressToBytes32[_addr] = _translateTo;
//     }

//     function getCurrentPrice(
//         address _srcAddress,
//         address _targetAddress
//     ) external payable override returns (uint256, uint256) {
//         bytes32 src = addressToBytes32[_srcAddress];
//         bytes32 target = addressToBytes32[_targetAddress];
//         require(src != bytes32(0), "src address not found");
//         require(target != bytes32(0), "target address not found");

//         uint256 srcValue = getOracleNumericValueFromTxMsg(src);
//         uint256 targetValue = getOracleNumericValueFromTxMsg(target);
//         return (srcValue, targetValue);
//     }
// }
