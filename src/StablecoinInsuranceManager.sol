// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStablecoinInsuranceManager} from "./IStablecoinInsuranceManager.sol";
import {StablecoinInsurancePolicy} from "./StablecoinInsurancePolicy.sol";
contract StablecoinInsuranceManager is IStablecoinInsuranceManager {
    uint256 nonce = 0;
    mapping(bytes32 => StablecoinInsurancePolicy) public policies;

    modifier requireApproveAndBalance(address _token, uint256 _amount) {
        IERC20 _tokenImpl = IERC20(_token);
        require(
            _tokenImpl.allowance(msg.sender, address(this)) >= _amount,
            "user not authorized to transfer"
        );
        require(
            _tokenImpl.balanceOf(msg.sender) >= _amount,
            "Insured must deposit the required amount"
        );
        _;
    }

    modifier requirePolicyExists(bytes32 _policyId) {
        require(
            address(policies[_policyId]) != address(0),
            "Policy does not exist"
        );
        _;
    }

    // Creates a new policy
    function createPolicy(
        address _insuredToken,
        address _insurerToken,
        address _policyManagerContract,
        uint256 _premiumAmount,
        uint256 _insuredAmount,
        uint256 _policyTermInSeconds,
        uint256 _depegTermInSeconds
    )
        external
        payable
        requireApproveAndBalance(_insuredToken, _insuredAmount + _premiumAmount)
        returns (bytes32)
    {
        IERC20 _insuredTokenImpl = IERC20(_insuredToken);
        StablecoinInsurancePolicy _policy = new StablecoinInsurancePolicy(
            msg.sender, //_insured
            _insuredToken, //_insuredToken
            _insurerToken, //_collateralToken
            _insuredToken, //_premiumToken
            _insuredAmount, //_insuredAmount
            _premiumAmount, //_premiumAmount
            _policyTermInSeconds, //_policyTermInSeconds
            _depegTermInSeconds, //_depegTermInSeconds
            address(this), //_dataprovider, currently unused
            address(this) //_managementContract
        );
        require(
            _insuredTokenImpl.transferFrom(
                msg.sender,
                address(_policy),
                _insuredAmount + _premiumAmount
            ),
            "failed to transfer funds"
        );
        bytes32 _policyId = keccak256(abi.encodePacked(nonce, _policy));
        nonce++;
        policies[_policyId] = _policy;
        return _policyId;
    }

    function activatePolicy(bytes32 _policyId) external override requirePolicyExists(_policyId) {
        StablecoinInsurancePolicy _policy = policies[_policyId];
        _policy.activatePolicy();
    }

    function cancelPolicy(bytes32 _policyId) external override requirePolicyExists(_policyId) {
        StablecoinInsurancePolicy _policy = policies[_policyId];
        _policy.cancelPolicy();
    }

    function recordPolicyDepeg(bytes32 _policyId) external override requirePolicyExists(_policyId) {
        StablecoinInsurancePolicy _policy = policies[_policyId];
        _policy.recordDepeg();
    }

    function getPolicy(
        bytes32 _policyId
    ) external view override returns (StablecoinInsurancePolicy) {
        return policies[_policyId];
    }

    function policyIsDepegged(
        bytes32 _policyId
    ) external view override returns (bool) {
        StablecoinInsurancePolicy _policy = policies[_policyId];
        return _policy.isDepegged();
    }
} 