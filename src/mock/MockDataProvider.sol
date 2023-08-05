// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../interfaces/IDataProviderAlt.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockDataProvider is IDataProviderAlt, Ownable {
    mapping(bytes32 => uint256) public priceMap;

    function setPrice(bytes32 _addr, uint256 _price) external onlyOwner {
        priceMap[_addr] = _price;
    }

    function getCurrentPrices(
        bytes32 _srcAddress,
        bytes32 _targetAddress
    ) external view override returns (uint256, uint256) {
        uint256 srcPrice = priceMap[_srcAddress];
        uint256 targetPrice = priceMap[_targetAddress];
        require(srcPrice != 0, "src price not found");
        require(targetPrice != 0, "target price not found");

        return (srcPrice, targetPrice);
    }
}
