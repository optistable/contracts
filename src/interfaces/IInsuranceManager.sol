// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface IInsuranceManager {
    /**
     * @dev Emitted when a new insurance policy is created.
     */
    event PolicyCreated(
        bytes32 indexed policyId,
        address indexed collateralToken,
        address indexed insuredToken,
        uint256 threshold
    );

    /**
     * @notice Creates a new insurance policy.
     * @param _collateralToken The token used as collateral for the policy.
     * @param _insuredToken The token that is being insured.
     * @param _threshold The threshold for the policy.
     * @return policyId The unique ID for the created policy.
     */
    function createPolicy(
        address _collateralToken,
        address _insuredToken,
        uint256 _threshold
    ) external returns (bytes32);

    /**
     * @notice Fetches the details of a specific policy.
     * @param _policyId The unique ID of the policy.
     * @return collateralToken The token used as collateral.
     * @return insuredToken The token that is being insured.
     * @return threshold The threshold for the policy.
     * @return insuranceContractAddress The address of the Insurance contract instance.
     */
    function getPolicy(
        bytes32 _policyId
    ) external view returns (
        address collateralToken,
        address insuredToken,
        uint256 threshold,
        address insuranceContractAddress
    );
}
