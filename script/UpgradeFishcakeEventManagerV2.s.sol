// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin-foundry-upgrades/Upgrades.sol";
import "forge-std/Script.sol";

import "forge-std/Vm.sol";

import {FishcakeEventManagerV2} from "../src/contracts/core/FishcakeEventManagerV2.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract FishcakeEventManagerV2Script is Script {
    address public constant PROXY_FISH_CAKE_EVENT_MANAGER =
        address(0x2CAf752814f244b3778e30c27051cc6B45CB1fc9);

    address public constant INITIAL_OWNER =
        0x7a129d41bb517aD9A6FA49afFAa92eBeea2DFe07;
    address public constant FCC_ADDRESS =
        0x84eBc138F4Ab844A3050a6059763D269dC9951c6;
    address public constant USDT_ADDRESS =
        0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public constant NFT_MANAGER =
        0x2F2Cb24BaB1b6E2353EF6246a2Ea4ce50487008B;

    ProxyAdmin public fishcakeEventManagerV2ProxyAdmin;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("deploy deployerAddress:", address(deployerAddress));

        // console.log("address(this):", address(this));

        vm.startBroadcast(deployerPrivateKey);
        FishcakeEventManagerV2 newImplementation = new FishcakeEventManagerV2();
        console.log(
            "New FishcakeEventManagerV2 implementation deployed at:",
            address(newImplementation)
        );

        // console.log(
        // //     "Proxy Admin:",
        //     Upgrades.getAdminAddress(PROXY_FISH_CAKE_EVENT_MANAGER)
        // );
        // console.log(
        //     "upgraded before:",
        //     Upgrades.getImplementationAddress(PROXY_FISH_CAKE_EVENT_MANAGER)
        // );

        // // 加入初始化 data
        // bytes memory data = abi.encodeCall(
        //     FishcakeEventManagerV2.initialize,
        //     (INITIAL_OWNER, FCC_ADDRESS, USDT_ADDRESS, NFT_MANAGER)
        // ); // 升级权限在 deployerAddress，逻辑权限在 INITIAL_OWNER

        // Upgrades.upgradeProxy(
        //     PROXY_FISH_CAKE_EVENT_MANAGER,
        //     "FishcakeEventManagerV2.sol:FishcakeEventManagerV2",
        //     "",
        //     deployerAddress
        // );

        fishcakeEventManagerV2ProxyAdmin = ProxyAdmin(
            getProxyAdminAddress(PROXY_FISH_CAKE_EVENT_MANAGER)
        );
        // Perform the upgrade
        fishcakeEventManagerV2ProxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(
                address(PROXY_FISH_CAKE_EVENT_MANAGER)
            ),
            address(newImplementation),
            ""
        );

        console.log("FishcakeEventManagerV2 proxy upgraded successfully");
        console.log(
            "======================================================================="
        );
        vm.stopBroadcast();
        console.log(
            "==========upgraded logic address after: ============",
            Upgrades.getImplementationAddress(PROXY_FISH_CAKE_EVENT_MANAGER)
        );
        console.log(
            "Proxy Admin:",
            Upgrades.getAdminAddress(PROXY_FISH_CAKE_EVENT_MANAGER)
        );

        FishcakeEventManagerV2 fishcakeEventManagerV2 = FishcakeEventManagerV2(
            payable(PROXY_FISH_CAKE_EVENT_MANAGER)
        );

        console.log("========Proxy:==========", PROXY_FISH_CAKE_EVENT_MANAGER);

        console.log("========Owner:==========", fishcakeEventManagerV2.owner());
    }

    function getProxyAdminAddress(
        address proxy
    ) internal view returns (address) {
        address CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
        Vm vm = Vm(CHEATCODE_ADDRESS);

        bytes32 adminSlot = vm.load(proxy, ERC1967Utils.ADMIN_SLOT);
        return address(uint160(uint256(adminSlot)));
    }
}
