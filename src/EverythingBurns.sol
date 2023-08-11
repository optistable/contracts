// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "forge-std/console.sol";

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract EverythingBurns is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }

    function burn(address form, uint256 amount) public virtual {
        _burn(form, amount);
    }
}
