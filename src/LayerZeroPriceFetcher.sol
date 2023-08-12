// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
pragma abicoder v2;

import "@layerzero/lzApp/NonblockingLzApp.sol";
import {AggregatorV3Interface} from "@chainlink/v0.8/interfaces/AggregatorV3Interface.sol";
import {IDataProvider} from "./interfaces/IDataProvider.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

/// @title This contract is deployed to Mumbai in our submission, and sends a message containing price data for a stablecoin to L1, where our app chain reads it into a data provider.
contract LayerZeroPriceFetcher is NonblockingLzApp {
    AggregatorV3Interface public stablecoinPriceFeed;
    IDataProvider public dataProvider;
    uint16 public adapterParamsVersion = 1;
    uint256 public gasForDestinationLzReceive = 500000;
    uint256 public lastObservedPrice;
    uint256 public lastObservedBlockNumber;

    //trustedRemoteLookup global variable comes from @layerzero/lzApp/LzApp.sol
    //lzEndpoint global variable comes from @layerzero/lzApp/LzApp.sol

    constructor(address _lzEndpoint, address _stablecoinPriceFeed, address _forwardToDataProvider)
        NonblockingLzApp(_lzEndpoint)
    {
        console.log("LayerZeroPriceFetcher constructor");
        console.log("LZ Endpoint: %s", _lzEndpoint);
        stablecoinPriceFeed = AggregatorV3Interface(_stablecoinPriceFeed);
        IDataProvider dataProvider = IDataProvider(_forwardToDataProvider);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload)
        internal
        override
    {
        console.log("Received a message from LayerZero %s", _srcChainId);
        // require(msg.sender == address(lzEndpoint), "received a message from an unknown source");

        // address fromAddress;
        // assembly {
        //     fromAddress := mload(add(_srcAddress, 20))
        // }
        // addrCounter[fromAddress] += 1;
        (uint256 price, uint256 srcBlockNumber) = abi.decode(_payload, (uint256, uint256));
        lastObservedPrice = price;
        lastObservedBlockNumber = srcBlockNumber;
        console.log("Recorded the following price %s on %s", price, srcBlockNumber);
        if (address(dataProvider) != address(0)) {
            dataProvider.recordPrice(price, srcBlockNumber);
        }
    }

    function estimateFee(
        uint16 _dstChainId,
        bool _useZro,
        int256 _price //int256 because that's what chainlink provides w/ raw value
    ) public view returns (uint256 nativeFee, uint256 zroFee) {
        console.log("Estimating fee for %s", _dstChainId);
        bytes memory dummyPayload = abi.encodePacked(uint256(_price), block.number, block.chainid);
        bytes memory adapterParams = abi.encodePacked(adapterParamsVersion, gasForDestinationLzReceive);
        return lzEndpoint.estimateFees(_dstChainId, address(this), dummyPayload, _useZro, adapterParams);
    }

    function sendPriceData(uint16 _dstChainId) public payable {
        console.log("Sending price data to %s", _dstChainId);
        require(address(stablecoinPriceFeed) != address(0), "stablecoin price feed not set, can't send a message");
        (, int256 answer,,,) = stablecoinPriceFeed.latestRoundData();
        console.log("Received answer", uint256(answer));
        bytes memory payload = abi.encodePacked(uint256(answer), block.number, block.chainid);
        bytes memory adapterParams = abi.encodePacked(adapterParamsVersion, gasForDestinationLzReceive);
        _lzSend(_dstChainId, payload, payable(msg.sender), address(0x0), adapterParams, msg.value);
    }

    function setDataProvider(address _dataProvider) external onlyOwner {
        dataProvider = IDataProvider(_dataProvider);
    }

    // function setOracle(uint16 dstChainId, address oracle) external onlyOwner {
    //     uint256 TYPE_ORACLE = 6;
    //     // set the Oracle
    //     lzEndpoint.setConfig(lzEndpoint.getSendVersion(address(this)), dstChainId, TYPE_ORACLE, abi.encode(oracle));
    // }

    // function getOracle(uint16 remoteChainId) external view returns (address _oracle) {
    //     bytes memory bytesOracle =
    //         lzEndpoint.getConfig(lzEndpoint.getSendVersion(address(this)), remoteChainId, address(this), 6);
    //     assembly {
    //         _oracle := mload(add(bytesOracle, 32))
    //     }
    // }

    // function setAdapterParamsVersion(uint16 _version) external onlyOwner {
    //     adapterParamsVersion = _version;
    // }

    // function setGasForDestinationLzReceive(uint256 _gas) external onlyOwner {
    //     gasForDestinationLzReceive = _gas;
    // }
}
