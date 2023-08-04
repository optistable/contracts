// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDataProvider {
    
    function getCurrentPrices(
        address insuredToken, //source coin
        address collateralToken //target coin
    ) external payable returns (uint256, uint256);

} 