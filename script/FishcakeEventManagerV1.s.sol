// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-foundry-upgrades/Upgrades.sol";
import {Script, console} from "forge-std/Script.sol";
import {FishcakeEventManagerV1} from "../src/contracts/core/FishcakeEventManagerV1.sol";

contract FishcakeEventManagerV1Script is Script {
    address public constant PROXY_FISH_CAKE_EVENT_MANAGER = address(0x2CAf752814f244b3778e30c27051cc6B45CB1fc9);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("deploy deployerAddress:", address(deployerAddress));

        vm.startBroadcast(deployerPrivateKey);
        FishcakeEventManagerV1 newImplementation = new FishcakeEventManagerV1();
        console.log("New FishcakeEventManagerV1 implementation deployed at:", address(newImplementation));

        console.log("upgraded before:", Upgrades.getImplementationAddress(PROXY_FISH_CAKE_EVENT_MANAGER));
        Upgrades.upgradeProxy(PROXY_FISH_CAKE_EVENT_MANAGER, "FishcakeEventManagerV1.sol:FishcakeEventManagerV1", "");
        console.log("NftManager proxy upgraded successfully");
        console.log("=======================================================================");
        vm.stopBroadcast();
        console.log("upgraded after:", Upgrades.getImplementationAddress(PROXY_FISH_CAKE_EVENT_MANAGER));
        console.log("Proxy Admin:", Upgrades.getAdminAddress(PROXY_FISH_CAKE_EVENT_MANAGER));
    }
}
