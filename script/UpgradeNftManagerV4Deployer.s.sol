// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin-foundry-upgrades/Upgrades.sol";

import {NftManagerV4} from "../src/contracts/core/token/NftManagerV4.sol";

contract UpgradeNftManagerV4DeployerScript is Script {
    // main network
    // address public constant PROXY_NFT_MANAGER = address(0x2F2Cb24BaB1b6E2353EF6246a2Ea4ce50487008B);

    // local
    address public constant PROXY_NFT_MANAGER = address(0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        NftManagerV4 newImplementation = new NftManagerV4();
        console.log("New newNftManager implementation deployed at:", address(newImplementation));

        vm.startBroadcast(deployerPrivateKey);
        console.log("upgraded before:", Upgrades.getImplementationAddress(PROXY_NFT_MANAGER));
        Upgrades.upgradeProxy(PROXY_NFT_MANAGER, "NftManagerV4.sol:NftManagerV4", "");
        vm.stopBroadcast();
        console.log("upgraded after:", Upgrades.getImplementationAddress(PROXY_NFT_MANAGER));
        console.log("Proxy Admin:", Upgrades.getAdminAddress(PROXY_NFT_MANAGER));

        console.log("NftManager proxy upgraded successfully");
        console.log("=======================================================================");
        console.log("Owner:", deployerAddress);
        console.log("New NftManagerV4 implementation:", address(newImplementation));
        console.log("NftManager proxy:", PROXY_NFT_MANAGER);

        // Verify upgraded state
        NftManagerV4 upgradedNftManager = NftManagerV4(payable(PROXY_NFT_MANAGER));
        console.log("Verifying upgraded state...");
        console.log("fccTokenAddr:", address(upgradedNftManager.fccTokenAddr()));
        console.log("tokenUsdtAddr:", address(upgradedNftManager.tokenUsdtAddr()));
        console.log("redemptionPoolAddress:", address(upgradedNftManager.redemptionPoolAddress()));

        console.log("New name:", upgradedNftManager.name());
        console.log("New symbol:", upgradedNftManager.symbol());
    }
}
