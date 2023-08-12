// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

// solhint-disable-next-line max-states-count
interface IPolicy {
    function createPolicy(
        uint256 blockNumber,
        address currencyInsured,
        address currencyInsurer,
        uint256 _policyPremiumPCT
    ) external;

    // Depeg occurs, policy executes and ends
    function depegEndPolicy(uint256 _policyId) external;

    // Subcribes to an upcoming policy as insured
    // TODO: frh -> add events, approve here and require blocknumber and TODOs from PR and deploy
    function subscribeAsInsured(uint256 _policyId, uint256 amount) external;
    // Subcribes to an upcoming policy as insurer
    function subscribeAsInsurer(uint256 _policyId, uint256 amount) external;

    function activatePolicy(uint256 _policyId) external;

    // Insured can withdraw whenever he want
    function withdrawAsInsured(uint256 _policyId, uint256 amount) external;

    // Insured can only withdraw after policy has ended
    function withdrawAsInsurer(uint256 _policyId, uint256 amount) external;

    function getSystemAddress() external view returns (address);
}
