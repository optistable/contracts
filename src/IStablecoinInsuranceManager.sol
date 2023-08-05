// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./StablecoinInsurancePolicy.sol";

interface IStablecoinInsuranceManager {
    
    // Creates a new policy 
    function createPolicy(
        address _insuredToken,
        address _insurerToken,
        address _policyManagerContract,
        uint256 _premiumAmount,
        uint256 _insuredAmount,
        uint256 _policyTermInSeconds,
        uint256 _depegTermInSeconds
    ) external payable returns (bytes32);

    function activatePolicy(bytes32 policyId) external;
    function cancelPolicy(bytes32 policyId) external;
    function recordPolicyDepeg(bytes32 policyId) external;
    function policyIsDepegged(bytes32 policyId) external view returns (bool);
    function getPolicy(bytes32 policyId) external view returns (StablecoinInsurancePolicy);
} 