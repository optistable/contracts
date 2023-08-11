// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

interface IDataProviderAlt {
    function getCurrentPrices(
        bytes32 insuredToken, //source coin
        bytes32 collateralToken //target coin
    ) external returns (uint256, uint256);
}
