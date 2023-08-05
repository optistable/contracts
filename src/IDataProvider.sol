// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDataProvider {
    function getCurrentPrice() external view returns (uint256, uint256);

    function getPriceAtBlockNum(
        uint256 _blocknum
    ) external view returns (uint256);

    function recordPrice(uint256 _blocknum, uint256 _price) external;

    function getSymbol() external view returns (bytes32);

    // Also indicates if this is on chain or not
    function getFeedAddress() external view returns (address);
}
