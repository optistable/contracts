// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "redstone-oracles-monorepo/packages/evm-connector/contracts/data-services/MainDemoConsumerBase.sol";
import "./IDataProvider.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

abstract contract RedstoneDataProvider is MainDemoConsumerBase, IDataProvider, Ownable {
    mapping(address => bytes32) public addressToBytes32;

    function addAddressMapping(address _addr, bytes32 _translateTo) external onlyOwner {
        addressToBytes32[_addr] = _translateTo;
    }

    function getCurrentPrice(address _srcAddress, address _targetAddress) external payable returns (uint256, uint256) {
        bytes32 src = addressToBytes32[_srcAddress];
        bytes32 target = addressToBytes32[_targetAddress];
        require(src != bytes32(0), "src address not found");
        require(target != bytes32(0), "target address not found");

        uint256 srcValue = getOracleNumericValueFromTxMsg(src);
        uint256 targetValue = getOracleNumericValueFromTxMsg(target);
        return (srcValue, targetValue);
    }
}
