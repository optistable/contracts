// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

interface IDataProvider {
    function recordPrice(uint256 _l1BlockNum, uint256 _price) external;

    function getLastPrice() external view returns (uint256);

    function getLastObservedBlock() external view returns (uint256);

    function getPriceAtBlockNum(uint256 _blocknum) external view returns (uint256);

    function getSymbol() external view returns (bytes32);

    function getEndingBlock() external view returns (uint256);

    function isOnChain() external view returns (bool);

    function isGasMinimized() external view returns (bool);
}
