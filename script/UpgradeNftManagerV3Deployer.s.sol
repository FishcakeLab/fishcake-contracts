// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin-foundry-upgrades/Upgrades.sol";

import {NftManagerV3} from "../src/contracts/core/token/NftManagerV3.sol";

contract UpgradeNftManagerV3Deployer is Script {
    // main network
    address public constant PROXY_NFT_MANAGER = address(0x2F2Cb24BaB1b6E2353EF6246a2Ea4ce50487008B);

    // local
//    address public constant PROXY_NFT_MANAGER = address(0x2a264F26859166C5BF3868A54593eE716AeBC848);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        NftManagerV3 newImplementation = new NftManagerV3();
        console.log("New newNftManager implementation deployed at:", address(newImplementation));

        console.log("Upgrading NftManager proxy...");
        vm.startBroadcast(deployerPrivateKey);

        console.log("Upgrading NftManager proxy...");
        console.log("upgraded before:", Upgrades.getImplementationAddress(PROXY_NFT_MANAGER));
        Upgrades.upgradeProxy(
            PROXY_NFT_MANAGER,
            "NftManagerV3.sol:NftManagerV3",
            ""
        );
        vm.stopBroadcast();
        console.log("upgraded after:", Upgrades.getImplementationAddress(PROXY_NFT_MANAGER));
        console.log("Proxy Admin:", Upgrades.getAdminAddress(PROXY_NFT_MANAGER));

        console.log("NftManager proxy upgraded successfully");
        console.log("=======================================================================");
        console.log("Owner:", deployerAddress);
        console.log("New NftManagerV3 implementation:", address(newImplementation));
        console.log("NftManager proxy:", PROXY_NFT_MANAGER);

        // Verify upgraded state
        NftManagerV3 upgradedNftManager = NftManagerV3(payable(PROXY_NFT_MANAGER));
        console.log("Verifying upgraded state...");
        console.log("fccTokenAddr:", address(upgradedNftManager.fccTokenAddr()));
        console.log("tokenUsdtAddr:", address(upgradedNftManager.tokenUsdtAddr()));
        console.log("redemptionPoolAddress:", address(upgradedNftManager.redemptionPoolAddress()));

        vm.startBroadcast(deployerPrivateKey);
        upgradedNftManager.updateNameAndSymbol("Fishcake Pass NFT", "FNFT");
        upgradedNftManager.updateNftJson(1, "https://www.fishcake.org/image/1.json");
        upgradedNftManager.updateNftJson(2, "https://www.fishcake.org/image/2.json");
        vm.stopBroadcast();

        console.log("New name:", upgradedNftManager.name());
        console.log("New symbol:", upgradedNftManager.symbol());


    }
}
