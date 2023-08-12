// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

// OracleCommittee sets up a series of data providers.
// When a majority of data providers report themselves as depegged, then it will report the policy as claimable
interface IOracleCommittee {
    function recordProviderAsDepegged() external;

    function getStartingBlock() external view returns (uint256);

    function getEndingBlock() external view returns (uint256);

    function isDepegged() external view returns (bool);

    function isClosed() external view returns (bool);

    function getProviders() external view returns (address[] memory);

    function getPolicyAddress() external view returns (address);

    function addExistingProvider(address _provider) external;

    // Shortcut, makes it easier
    function addNewProvider(
        bytes32 _oracleType,
        uint256 _depegTolerance,
        uint8 _minBlocksToSwitchStatus,
        uint8 _decimals,
        bool _isOnChain
    ) external returns (address);
}
