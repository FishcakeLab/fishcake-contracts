// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin-foundry-upgrades/Upgrades.sol";
import  "forge-std/Script.sol";
import {FishcakeEventManagerV2} from "../src/contracts/core/FishcakeEventManagerV2.sol";

contract FishcakeEventManagerV2Script is Script {
    address public constant PROXY_FISH_CAKE_EVENT_MANAGER = address(0x2CAf752814f244b3778e30c27051cc6B45CB1fc9);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("deploy deployerAddress:", address(deployerAddress));

        console.log("address(this):", address(this));

        vm.startBroadcast(deployerPrivateKey);
        FishcakeEventManagerV2 newImplementation = new FishcakeEventManagerV2();
        console.log("New FishcakeEventManagerV2 implementation deployed at:", address(newImplementation));

        console.log("Proxy Admin:", Upgrades.getAdminAddress(PROXY_FISH_CAKE_EVENT_MANAGER));
        console.log("upgraded before:", Upgrades.getImplementationAddress(PROXY_FISH_CAKE_EVENT_MANAGER));

        Upgrades.upgradeProxy(PROXY_FISH_CAKE_EVENT_MANAGER, "FishcakeEventManagerV2.sol:FishcakeEventManagerV2", "", deployerAddress);
        console.log("FishcakeEventManagerV2 proxy upgraded successfully");
        console.log("=======================================================================");
        vm.stopBroadcast();
        console.log("upgraded after:", Upgrades.getImplementationAddress(PROXY_FISH_CAKE_EVENT_MANAGER));
        console.log("Proxy Admin:", Upgrades.getAdminAddress(PROXY_FISH_CAKE_EVENT_MANAGER));
    }
}
