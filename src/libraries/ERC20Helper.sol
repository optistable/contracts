// solhint-disable avoid-low-level-calls
/// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

library ERC20Helper {
    // function allowance(address owner, address spender) external view returns (uint256);

    function allowance(address token, address account) internal returns (uint256) {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.allowance.selector, account, address(this)));
        require(success, "Error getting allowance");
        return abi.decode(data, (uint256));
    }

    function balanceOf(address token, address account) internal returns (uint256) {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.balanceOf.selector, account));
        require(success, "Error getting balance");
        return abi.decode(data, (uint256));
    }

    function decimals(address token) internal returns (uint256) {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("decimals()"));
        require(success, "Error getting decimals");
        return abi.decode(data, (uint256));
    }

    function name(address token) internal returns (string memory) {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("name()"));
        require(success, "Error getting name");
        return abi.decode(data, (string));
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
    }

    function symbol(address token) internal returns (string memory) {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("symbol()"));
        require(success, "Error getting symbol");
        return abi.decode(data, (string));
    }
}
