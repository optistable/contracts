// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import {IDataProvider} from "./IDataProvider.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract ChainlinkPriceFeedDataProvider is IDataProvider, Ownable {
    bytes32 public symbol;
    uint256 public lastBlockNum;
    uint256 public lastObservation;
    address public feedAddress;
    address public systemAddress;

    mapping(uint256 => uint256) public history;

    constructor(address _feed, bytes32 _symbol) {
        feedAddress = _feed;
        symbol = _symbol;
    }

    function recordPrice(uint256 _blocknum, uint256 _price) external {
        require(msg.sender == systemAddress, "only the system address can ");
        history[_blocknum] = _price;
        lastObservation = _price;
        lastBlockNum = _blocknum; //TODO This must come from L1
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

    function getCurrentPrice() external view returns (uint256, uint256) {
        return (lastBlockNum, lastObservation);
    }

    function getPriceAtBlockNum(uint256 _blocknum) external view returns (uint256) {
        return history[_blocknum];
    }

    function getSymbol() external view returns (bytes32) {
        return symbol;
    }

    function getSystemAddress() external view returns (address) {
        return systemAddress;
    }

    function getFeedAddress() external view returns (address) {
        return feedAddress;
    }
}
