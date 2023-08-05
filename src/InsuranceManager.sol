// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IInsuranceManager} from "./interfaces/IInsuranceManager.sol";
import {Insurance} from "./Insurance.sol";

contract InsuranceManager is IInsuranceManager {

    struct InsurancePolicy {
        address collateralToken;
        address insuredToken;
        uint256 threshold;
        Insurance insuranceContract; // The actual contract instance where the policy lives
    }

    mapping(bytes32 => InsurancePolicy) public policies;

    // Event to notify the creation of a policy
    event PolicyCreated(bytes32 indexed policyId, address collateralToken, address insuredToken, uint256 threshold);

    // Creates a new policy
    function createPolicy(
        address _collateralToken, 
        address _insuredToken, 
        uint256 _threshold
    ) external override returns (bytes32) {
        // create unique policy id based on the collateral and insured token and threshold
        bytes32 policyId = keccak256(abi.encodePacked(_collateralToken, _insuredToken, _threshold));
        
        require(
            policies[policyId].collateralToken == address(0) &&
            policies[policyId].insuredToken == address(0) &&
            policies[policyId].threshold == 0,
            "Policy already exists"
        );
        
        Insurance newInsuranceContract = new Insurance(); // create a new Insurance contract instance (assuming its constructor doesn't require parameters)

        policies[policyId] = InsurancePolicy({
            collateralToken: _collateralToken,
            insuredToken: _insuredToken,
            threshold: _threshold,
            insuranceContract: newInsuranceContract
        });

        emit PolicyCreated(policyId, _collateralToken, _insuredToken, _threshold);

        return policyId;
    }

    function getPolicy(
        bytes32 _policyId
    ) external view override returns (address, address, uint256, address) {
        require(policies[_policyId].collateralToken != address(0), "Policy does not exist");

        InsurancePolicy memory policy = policies[_policyId];
        return (
            policy.collateralToken,
            policy.insuredToken,
            policy.threshold,
            address(policy.insuranceContract)
        );
    }
}
