// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin-foundry-upgrades/Upgrades.sol";

import {NftManagerV5} from "../src/contracts/core/token/NftManagerV5.sol";

contract UpgradeNftManagerV5DeployerScript is Script {
    address public constant INITIAL_OWNER =
        0x7a129d41bb517aD9A6FA49afFAa92eBeea2DFe07;
    address public constant FCC_ADDRESS =
        0x84eBc138F4Ab844A3050a6059763D269dC9951c6;
    address public constant USDT_ADDRESS =
        0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public constant REDEMPT_POOL =
        0x036423643CEB603B7aff40A05627F09C04b9897E;

    // main network
    address public constant PROXY_NFT_MANAGER =
        address(0x2F2Cb24BaB1b6E2353EF6246a2Ea4ce50487008B);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        NftManagerV5 newImplementation = new NftManagerV5();
        console.log(
            "New newNftManager implementation deployed at:",
            address(newImplementation)
        );

        vm.startBroadcast(deployerPrivateKey);
        console.log(
            "upgraded before:",
            Upgrades.getImplementationAddress(PROXY_NFT_MANAGER)
        );
        Upgrades.upgradeProxy(
            PROXY_NFT_MANAGER,
            "NftManagerV5.sol:NftManagerV5",
            ""
        );
        vm.stopBroadcast();
        console.log(
            "upgraded after:",
            Upgrades.getImplementationAddress(PROXY_NFT_MANAGER)
        );
        console.log(
            "Proxy Admin:",
            Upgrades.getAdminAddress(PROXY_NFT_MANAGER)
        );

        console.log("NftManager proxy upgraded successfully");
        console.log(
            "======================================================================="
        );
        console.log("Owner:", deployerAddress);
        console.log(
            "New NftManagerV5 implementation:",
            address(newImplementation)
        );
        console.log("NftManager proxy:", PROXY_NFT_MANAGER);

        // Verify upgraded state
        NftManagerV5 upgradedNftManager = NftManagerV5(
            payable(PROXY_NFT_MANAGER)
        );
        upgradedNftManager.initialize(
            INITIAL_OWNER,
            FCC_ADDRESS,
            USDT_ADDRESS,
            REDEMPT_POOL
        );
        console.log("Verifying upgraded state...");
        console.log(
            "fccTokenAddr:",
            address(upgradedNftManager.fccTokenAddr())
        );
        console.log(
            "tokenUsdtAddr:",
            address(upgradedNftManager.tokenUsdtAddr())
        );
        console.log(
            "redemptionPoolAddress:",
            address(upgradedNftManager.redemptionPoolAddress())
        );

        console.log("New name:", upgradedNftManager.name());
        console.log("New symbol:", upgradedNftManager.symbol());
    }
}
