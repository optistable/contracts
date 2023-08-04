// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStablecoinInsurancePolicy {
    
    function isDepegged() external view returns (bool);
    function recordDepeg() external;
    function cancelPolicy() external;

} 