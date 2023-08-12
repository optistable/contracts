// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import {IDataProvider} from "./IDataProvider.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/v0.8/interfaces/AggregatorV3Interface.sol";
import {OracleCommittee} from "./OracleCommittee.sol";

import "forge-std/console.sol";

contract GenericDataProvider is IDataProvider, Ownable {
    bytes32 public symbol;
    uint256 public lastBlockNum;
    uint256 public depegTolerance;
    address public systemAddress;
    uint8 public minBlocksToSwitchStatus;
    bool public onChain;
    // resets as a token fluctuates between stable and depegged,
    uint8 public switchStatusCounter;
    uint8 public decimals;
    bool public depegged = false;
    uint256 public stableValue; //Will be 1 ** decimals, see comment in recordPrice.
    uint256 public lastObservation;
    bytes32 public oracleType; // used to dictate behavior to the rollup
    bool public lastObservationDepegged = false; //informational only
    OracleCommittee committee;

    event DataProviderCreated(
        address indexed committeeAddress,
        address indexed policyAddress,
        bytes32 indexed symbol,
        bytes32 oracleType,
        uint256 depegTolerance,
        uint8 minBlocksToSwitchStatus,
        uint8 decimals,
        bool onChain,
        uint256 stableValue
    );
    event PriceRecorded(
        address indexed committeeAddress,
        address indexed policyAddress,
        bytes32 indexed symbol,
        uint256 l1BlockNum,
        uint256 price,
        bool depegged
    );

    constructor(
        bytes32 _oracleType,
        address _systemAddress, // The address authorized to record prices
        address _committeeAddress,
        bytes32 _symbol,
        uint256 _depegTolerance,
        uint8 _minBlocksToSwitchStatus,
        uint8 _decimals,
        bool _isOnchain
    ) {
        oracleType = _oracleType;
        symbol = _symbol;
        minBlocksToSwitchStatus = _minBlocksToSwitchStatus;
        systemAddress = _systemAddress;
        decimals = _decimals;
        stableValue = 10 ** _decimals;
        depegTolerance = _depegTolerance;
        onChain = _isOnchain;
        committee = OracleCommittee(_committeeAddress);
        emit DataProviderCreated(
            _committeeAddress,
            committee.getPolicyAddress(),
            _symbol,
            _oracleType,
            _depegTolerance,
            _minBlocksToSwitchStatus,
            _decimals,
            _isOnchain,
            stableValue
        );
    }

    // Strictly a debug function for avichal
    function shouldRecordPrice(uint256 _l1BlockNum) external view returns (bool) {
        if (address(committee) == address(0)) {
            console.log("false, no committee");
            return false;
        }
        if (_l1BlockNum > committee.getEndingBlock()) {
            console.log("false, _l1BlockNum > committee.getEndingBlock()");
            return false;
        }
        if (_l1BlockNum <= lastBlockNum) {
            console.log("false, _l1BlockNum <= lastBlockNum");
            return false;
        }
        if (depegged) {
            console.log("false, depegged");
            return false;
        }
        return true;
    }

    function recordPrice(uint256 _l1BlockNum, uint256 _price) external virtual {
        require(address(committee) != address(0), "this data provider has not been assigned to a committee");
        require(!depegged, "this data provider has concluded, marking this stablecoin as depegged");
        console.log("recordPrice %s %s %s %s", _l1BlockNum);
        require(_l1BlockNum <= committee.getEndingBlock(), "this data provider has finished recording prices");
        require(_l1BlockNum > lastBlockNum, "have already recorded price for this block");
        require(msg.sender == systemAddress, "only the system address can record a price");

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
        emit PriceRecorded(
            address(committee), committee.getPolicyAddress(), symbol, _l1BlockNum, _price, currentlyDepegged
        );
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

    function isDepegged() external view returns (bool) {
        return depegged;
    }

    function isGasMinimized() external view virtual returns (bool) {
        return true;
    }

    function isOnChain() external view returns (bool) {
        return onChain;
    }

    function getType() external view returns (bytes32) {
        return oracleType;
    }

    function setOracleCommittee(address _oracleCommitteeAddr) external {
        require(msg.sender == systemAddress, "only the system address can change the oracle");
        require(address(committee) == address(0), "the committee has already been set, can no longer be changed");
        committee = OracleCommittee(_oracleCommitteeAddr);
    }

    function getOracleCommittee() external view returns (address) {
        return address(committee);
    }
}
