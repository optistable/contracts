// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract PolicyWrapper is ERC20("MockERC20", "ERC20", 18), Ownable {
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function setName(string calldata _name) external onlyOwner {
        name = _name;
    }

    function setSymbol(string calldata _symbol) external onlyOwner {
        symbol = _symbol;
    }
}
