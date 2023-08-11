// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import {IDataProvider} from "./IDataProvider.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/v0.8/interfaces/AggregatorV3Interface.sol";
import {OracleCommittee} from "./OracleCommittee.sol";

import "forge-std/console.sol";

contract ChainlinkPriceFeedDataProvider is IDataProvider, Ownable {
    bytes32 public symbol;
    uint256 public lastBlockNum;
    uint256 public endingBlock;
    uint256 public depegTolerance;
    AggregatorV3Interface public l1Feed;
    address public systemAddress;
    uint8 public minBlocksToSwitchStatus;
    // resets as a token fluctuates between stable and depegged,
    uint8 public switchStatusCounter;
    uint8 private decimals;
    bool public depegged = false;
    uint256 stableValue; //Will be 1a ** decimals, see comment in recordPrice.
    uint256 public lastObservation;
    bool private lastObservationDepegged = false;
    bytes32 oracleType = bytes32("chainlink-data-feed");
    OracleCommittee committee;

    constructor(
        address _feed,
        address _systemAddress, // The address authorized to record prices
        bytes32 _symbol,
        uint256 _depegTolerance,
        uint8 _minBlocksToSwitchStatus,
        uint8 _decimals
    ) {
        l1Feed = AggregatorV3Interface(_feed);
        symbol = _symbol;
        minBlocksToSwitchStatus = _minBlocksToSwitchStatus;
        systemAddress = _systemAddress;
        decimals = _decimals;
        stableValue = 10 ** _decimals;
        depegTolerance = _depegTolerance;
    }

    function recordPrice(uint256 _l1BlockNum, uint256 _price) external virtual {
        require(address(committee) != address(0), "this data provider has not been assigned to a committee");
        require(!depegged, "this data provider has concluded, marking this stablecoin as depegged");
        require(_l1BlockNum <= endingBlock, "this data provider has finished recording prices");
        require(_l1BlockNum >= lastBlockNum, "have already recorded price for this block");
        require(msg.sender == systemAddress, "only the system address can record a price");

        // console.log("recording price of ", _price, " at blocknum ", _l1BlockNum);

        bool currentlyDepegged = stableValue - _price >= depegTolerance;
        if (currentlyDepegged) {
            //Token is depegged
            switchStatusCounter++;
        } else {
            //Token is not depegged
            switchStatusCounter = 0; //Reset counter
        }

        if (switchStatusCounter >= minBlocksToSwitchStatus) {
            depegged = true;
            // This data provider will count as one of many sources of truth that this stablecoin is depegged
            committee.recordProviderAsDepegged();
        }
        lastBlockNum = _l1BlockNum;
        lastObservation = _price;
        lastObservationDepegged = currentlyDepegged;
    }

    function getLastPrice() external view returns (uint256) {
        return lastObservation;
    }

    function getLastObservedBlock() external view returns (uint256) {
        return lastBlockNum;
    }

    function getSymbol() external view returns (bytes32) {
        return symbol;
    }

    function getSystemAddress() external view returns (address) {
        return systemAddress;
    }

    function getL1Feed() external view returns (AggregatorV3Interface) {
        return l1Feed;
    }

    function getFeedAddress() external view returns (address) {
        return address(l1Feed);
    }

    function isDepegged() external view returns (bool) {
        return depegged;
    }

    function getPriceAtBlockNum(uint256 _blocknum) external view virtual returns (uint256) {
        require(false, "you can't view price history when minimizeGas is true");
        return 0; //Can never be reached
    }

    function getEndingBlock() external view returns (uint256) {
        return endingBlock;
    }

    function isGasMinimized() external view virtual returns (bool) {
        return true;
    }

    function isOnChain() external view returns (bool) {
        return true;
    }

    function getType() external view returns (bytes32) {
        return oracleType;
    }

    function setOracleCommittee(address _oracleCommitteeAddr) external {
        require(msg.sender == systemAddress, "only the system address can change the oracle");
        require(address(committee) == address(0), "the committee has already been set, can no longer be changed");
        committee = OracleCommittee(_oracleCommitteeAddr);
    }
}
