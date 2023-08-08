// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import {IDataProvider} from "./IDataProvider.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/v0.8/interfaces/AggregatorV3Interface.sol";
import {ChainlinkPriceFeedDataProvider} from "./ChainlinkPriceFeedDataProvider.sol";
import "forge-std/console.sol";

contract ChainlinkPriceFeedDataProviderDebug is ChainlinkPriceFeedDataProvider {
    // We deploy new DataProviders when we create a policy, so the history shouldn't get out of control
    mapping(uint256 => uint256) priceAtBlock;

    constructor(
        address _feed,
        address _systemAddress, // The address authorized to record prices
        // address _committeeAddress, // The address where central config comes from
        bytes32 _symbol,
        uint256 _depegTolerance,
        uint8 _minBlocksToSwitchStatus,
        uint8 _decimals
    )
        ChainlinkPriceFeedDataProvider(
            _feed,
            _systemAddress,
            _symbol,
            _depegTolerance,
            _minBlocksToSwitchStatus,
            _decimals
        )
    {}

    function recordPrice(uint256 _l1BlockNum, uint256 _price) external override {
        //TODO fix below
        // super.recordPrice(_l1BlockNum, _price);
        //Optional storage. Great for debugging, horrible for users

        priceAtBlock[_l1BlockNum] = _price;
    }

    function getPriceAtBlockNum(uint256 _l1Blocknum) external view override returns (uint256) {
        return priceAtBlock[_l1Blocknum]; //Can never be reached
    }

    function isGasMinimized() external view override returns (bool) {
        return false;
    }
}
