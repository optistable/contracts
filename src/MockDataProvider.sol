// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "./IDataProviderAlt.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract MockDataProvider is IDataProviderAlt, Ownable {
    mapping(bytes32 => uint256) public priceMap;

    function forcePrice(bytes32 _addr, uint256 _price) external onlyOwner {
        priceMap[_addr] = _price;
    }

    function getCurrentPrices(bytes32 _srcAddress, bytes32 _targetAddress)
        external
        view
        override
        returns (uint256, uint256)
    {
        uint256 srcPrice = priceMap[_srcAddress];
        uint256 targetPrice = priceMap[_targetAddress];
        require(srcPrice != 0, "src price not found");
        require(targetPrice != 0, "target price not found");

        return (srcPrice, targetPrice);
    }
}
