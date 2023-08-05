// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDataProvider {
    function getCurrentPrice() external returns (uint64, uint256);

    function getPriceAtBlockNum(uint64 _blocknum) external returns (uint256);

    function recordPrice(uint64 _blocknum) external;

    function getSymbol() external returns (bytes32);
}
