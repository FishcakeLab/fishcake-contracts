// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract FccToken is ERC20, Ownable, ERC20Permit {
    constructor(address initialOwner) ERC20("FccToken", "FCC") Ownable(initialOwner) ERC20Permit("FccToken") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
