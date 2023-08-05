// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IDataProvider} from "./IDataProvider.sol";

contract ChainlinkPriceFeedDataProvider is IDataProvider {
    bytes32 symbol;
    uint256 lastBlockNum;
    uint256 lastObservation;

    constructor(address _feed, bytes32 _symbol) {}

    function getCurrentPrice() external returns (uint64, uint256) {}

    function getPriceAtBlockNum(uint64 _blocknum) external returns (uint256) {}

    function recordPrice(uint64 _blocknum) external {
        lastBlockNum = _blocknum; //TODO This must come from L1
    }

    function getSymbol() external returns (bytes32) {}

    function setSymbol(bytes32 _newSymbol) external onlyOwner {}
}
