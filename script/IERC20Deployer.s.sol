// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Script, console} from "forge-std/Script.sol";

contract FccUsdtERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}

contract IERC20Deployer is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        address testAddress = address(0x15FC368F7F8BfF752119cda045fcE815dc8F053A);

        vm.startBroadcast(deployerPrivateKey);

        // can not upgrade
        IERC20 fcc_usdt_token = new FccUsdtERC20("FCC_USDT", "FCC_USDT", 12345678910 * 1e18, deployerAddress);
        console.log("deploy fcc_usdt_token:", address(fcc_usdt_token));
        console.log("deploy deployerAddress balance:", fcc_usdt_token.balanceOf(deployerAddress));

        fcc_usdt_token.transfer(testAddress, 1000 * 1e18);
        console.log("deploy deployerAddress balance:", fcc_usdt_token.balanceOf(deployerAddress));
        console.log("deploy testAddress balance:", fcc_usdt_token.balanceOf(testAddress));

        vm.stopBroadcast();
    }
}
