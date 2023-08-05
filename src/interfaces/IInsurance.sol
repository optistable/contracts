// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

/**
 * @title IInsurance Interface
 * @dev This interface represents the primary interactions with the Insurance contract.
 * It includes the structure of Insured and Insurer participants and the main functions
 * they can execute.
 */
interface IInsurance {
    function getPossibleInsurerMatches(address insuredAddress) external view returns(address[] memory);
    function addInsured(uint256 _amount, uint256 _insuranceTimeInSeconds, address insurerAddress) external;
    function addInsurer(uint256 _amount, uint256 _insuranceTimeInSeconds) external;
    function claimInsurance() external;
    function claimPremium() external;
}
