// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IDataProvider} from "./IDataProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ChainlinkPriceFeedDataProvider is IDataProvider, Ownable {
    bytes32 symbol;
    uint256 lastBlockNum;
    uint256 lastObservation;
    address feedAddress;
    address systemAddress;

    mapping(uint256 => uint256) history;

    constructor(address _feed, bytes32 _symbol) {
        feedAddress = _feed;
        symbol = _symbol;
    }

    function getCurrentPrice() external view returns (uint256, uint256) {
        return (lastBlockNum, lastObservation);
    }

    function getPriceAtBlockNum(
        uint256 _blocknum
    ) external view returns (uint256) {
        return history[_blocknum];
    }

    function recordPrice(uint256 _blocknum, uint256 _price) external {
        history[_blocknum] = _price;
        lastObservation = _price;
        lastBlockNum = _blocknum; //TODO This must come from L1
    }

    function getSymbol() external view returns (bytes32) {
        return symbol;
    }

    function setSymbol(bytes32 _newSymbol) external onlyOwner {
        symbol = _newSymbol;
    }

    function setFeedAddress(address _newFeedAddress) external onlyOwner {
        feedAddress = _newFeedAddress;
    }

    function setSystemAddress(address _newSystemAddress) external onlyOwner {
        systemAddress = _newSystemAddress;
    }

    function getFeedAddress() external view returns (address) {
        return feedAddress;
    }
}
