// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract PolicyWrapper is ERC20("MockERC20", "ERC20", 18), Ownable {
    address[] public minters;

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        minters.push(to);
    }

    function setName(string calldata _name) external onlyOwner {
        name = _name;
    }

    function setSymbol(string calldata _symbol) external onlyOwner {
        symbol = _symbol;
    }

    function getMinter(uint256 index) external view onlyOwner returns (address) {
        return minters[index];
    }

    function getMintersLength() external view onlyOwner returns (uint256) {
        return minters.length;
    }
}
