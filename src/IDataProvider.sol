// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

interface IDataProvider {
    function recordPrice(uint256 _l1BlockNum, uint256 _price) external;

    function getLastPrice() external view returns (uint256);

    function getLastObservedBlock() external view returns (uint256);

    function getSymbol() external view returns (bytes32);

    function isOnChain() external view returns (bool);

    function isGasMinimized() external view returns (bool);

    function setOracleCommittee(address _oracleCommitteeAddr) external;

    // Returns the type of oracle service that this Data Provider represents
    // Valid values are determined by the derivation layer of the rollup in our OP Stack hack
    // Currently expected is: "chainlink-data-feed" "chainlink-ccip" "redstone" and "coingecko"
    function getType() external view returns (bytes32);
}
