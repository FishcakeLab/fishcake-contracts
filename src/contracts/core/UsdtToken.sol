// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title just for test .
 * @dev UsdtToken is an ERC20 token .
 */
contract UsdtToken is ERC20, Ownable, ERC20Permit {
    constructor(address initialOwner) ERC20("USDT", "USDT") Ownable(initialOwner) ERC20Permit("USDT") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    function decimals() public view virtual override returns (uint8) {
        return 6; 
    }
}
