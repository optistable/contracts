// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface IInsuranceManager {

    function createPolicy(
        address _collateralToken, 
        address _insuredToken, 
        uint256 _threshold,
        uint256 _depegTermInSeconds,
        uint256 _depegThreshold,
        uint256 _premiumRate,
        address _dataProvider
    ) external returns (bytes32);

    function getPolicy(
        bytes32 _policyId
    ) external view returns (
        address collateralToken,
        address insuredToken,
        uint256 threshold,
        address insuranceContractAddress
    );
}
