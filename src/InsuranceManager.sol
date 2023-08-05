// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IInsuranceManager} from "./interfaces/IInsuranceManager.sol";
import {Insurance} from "./Insurance.sol";

contract InsuranceManager is IInsuranceManager {

    address public owner;

    struct InsurancePolicy {
        address collateralToken;
        address insuredToken;
        uint256 threshold;
        Insurance insuranceContract;
    }

    mapping(bytes32 => InsurancePolicy) public policies;

    event PolicyCreated(bytes32 indexed policyId, address collateralToken, address insuredToken, uint256 threshold);
    
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Creates a new insurance policy.
     * 
     * @param _collateralToken Address of the collateral token for the new policy
     * @param _insuredToken Address of the insured token for the new policy
     * @param _threshold Threshold value for the new policy
     * @param _depegTermInSeconds Depeg term duration for the insurance
     * @param _depegThreshold Depeg threshold for the insurance
     * @param _premiumRate Premium rate for the insurance policy
     * @param _dataProvider Address of the data provider contract
     * 
     * @return policyId Unique identifier for the created policy
     */
    function createPolicy(
        address _collateralToken, 
        address _insuredToken, 
        uint256 _threshold,
        uint256 _depegTermInSeconds,
        uint256 _depegThreshold,
        uint256 _premiumRate,
        address _dataProvider
    ) external returns (bytes32) {
        // Create unique policy id based on the collateral and insured token and threshold
        bytes32 policyId = keccak256(abi.encodePacked(_collateralToken, _insuredToken, _threshold));
        
        require(
            policies[policyId].collateralToken == address(0) &&
            policies[policyId].insuredToken == address(0) &&
            policies[policyId].threshold == 0,
            "Policy already exists"
        );
        
        // Create a new Insurance contract instance
        Insurance newInsuranceContract = new Insurance(
            _insuredToken,
            _collateralToken,
            _depegTermInSeconds,
            _depegThreshold,
            _premiumRate,
            _dataProvider,
            address(this) // Management contract is this InsuranceManager contract
        );

        policies[policyId] = InsurancePolicy({
            collateralToken: _collateralToken,
            insuredToken: _insuredToken,
            threshold: _threshold,
            insuranceContract: newInsuranceContract
        });

        emit PolicyCreated(policyId, _collateralToken, _insuredToken, _threshold);

        return policyId;
    }

    /**
     * @dev Fetches details of an existing insurance policy.
     * 
     * @param _policyId Unique identifier of the policy to fetch
     * 
     * @return collateralToken Address of the collateral token for the policy
     * @return insuredToken Address of the insured token for the policy
     * @return threshold Threshold value of the policy
     * @return insuranceContract Address of the deployed Insurance contract for this policy
     */
    function getPolicy(
        bytes32 _policyId
    ) external view override returns (address collateralToken, address insuredToken, uint256 threshold, address insuranceContract) {
        require(policies[_policyId].collateralToken != address(0), "Policy does not exist");

        InsurancePolicy storage policy = policies[_policyId];
        return (
            policy.collateralToken,
            policy.insuredToken,
            policy.threshold,
            address(policy.insuranceContract)
        );
    }
}
