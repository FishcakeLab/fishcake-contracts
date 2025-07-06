// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin-foundry-upgrades/Upgrades.sol";
import  "forge-std/Script.sol";
import { DirectSalePoolV1 } from "../src/contracts/core/sale/DirectSalePoolV1.sol";

contract UpgradeDirectSalePoolV1Script is Script {
    address public constant PROXY_DIRECT_SALE_POOL = address(0xF71C97C9C6B2133A0Cb5c3ED4CC6eFe5e1BC534C);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("deploy deployerAddress:", address(deployerAddress));

        console.log("address(this):", address(this));

        vm.startBroadcast(deployerPrivateKey);
        DirectSalePoolV1 newImplementation = new DirectSalePoolV1();
        console.log("New DirectSalePoolV1 implementation deployed at:", address(newImplementation));

        console.log("DirectSalePool Proxy Admin:", Upgrades.getAdminAddress(PROXY_DIRECT_SALE_POOL));
        console.log("DirectSalePool upgraded before:", Upgrades.getImplementationAddress(PROXY_DIRECT_SALE_POOL));

        Upgrades.upgradeProxy(PROXY_DIRECT_SALE_POOL, "DirectSalePoolV1.sol:DirectSalePoolV1", "", deployerAddress);
        console.log("DirectSalePoolV1 proxy upgraded successfully");
        vm.stopBroadcast();


        console.log("DirectSalePool upgraded after:", Upgrades.getImplementationAddress(PROXY_DIRECT_SALE_POOL));
        console.log("DirectSalePool Proxy Admin:", Upgrades.getAdminAddress(PROXY_DIRECT_SALE_POOL));
    }
}
