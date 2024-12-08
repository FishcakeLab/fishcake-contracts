// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin-foundry-upgrades/Upgrades.sol";

import {NftManagerV2} from "../src/contracts/core/token/NftManagerV2.sol";

contract UpgradeNftManagerDeployer is Script {
    // main network
     address public constant PROXY_NFT_MANAGER = address(0x2F2Cb24BaB1b6E2353EF6246a2Ea4ce50487008B);

    // local
//    address public constant PROXY_NFT_MANAGER = address(0x2a264F26859166C5BF3868A54593eE716AeBC848);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        NftManagerV2 newNftManager = new NftManagerV2();
        console.log("New newNftManager implementation deployed at:", address(newNftManager));

        console.log("Upgrading NftManager proxy...");
        vm.startBroadcast(deployerPrivateKey);

        Upgrades.upgradeProxy(
            PROXY_NFT_MANAGER,
            "NftManagerV2.sol:NftManagerV2",
            ""
        );
        vm.stopBroadcast();

        console.log("NftManager proxy upgraded successfully");
        console.log("=======================================================================");
        console.log("Owner:", deployerAddress);
        console.log("New NftManagerV2 implementation:", address(newNftManager));
        console.log("NftManager proxy:", PROXY_NFT_MANAGER);

        NftManagerV2 upgradedNftManager = NftManagerV2(payable(PROXY_NFT_MANAGER));
        console.log("Verifying upgraded state...");
        console.log("fccTokenAddr:", address(upgradedNftManager.fccTokenAddr()));
        console.log("tokenUsdtAddr:", address(upgradedNftManager.tokenUsdtAddr()));
        console.log("redemptionPoolAddress:", address(upgradedNftManager.redemptionPoolAddress()));

    }
}
