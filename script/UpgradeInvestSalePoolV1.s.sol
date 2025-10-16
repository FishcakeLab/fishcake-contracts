// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin-foundry-upgrades/Upgrades.sol";
import "forge-std/Script.sol";
import {InvestorSalePool} from "../src/contracts/core/sale/InvestorSalePool.sol";

contract UpgradeInvestorSalePoolScript is Script {
    address public constant INITIAL_OWNER =
        0x7a129d41bb517aD9A6FA49afFAa92eBeea2DFe07;
    address public constant FCC_ADDRESS =
        0x84eBc138F4Ab844A3050a6059763D269dC9951c6;
    address public constant USDT_ADDRESS =
        0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public constant REDEMPT_POOL =
        0x036423643CEB603B7aff40A05627F09C04b9897E;

    address public constant PROXY_DIRECT_SALE_POOL =
        address(0xF71C97C9C6B2133A0Cb5c3ED4CC6eFe5e1BC534C);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("deploy deployerAddress:", address(deployerAddress));

        console.log("address(this):", address(this));

        vm.startBroadcast(deployerPrivateKey);
        InvestorSalePool newImplementation = new InvestorSalePool();
        console.log(
            "New InvestorSalePool implementation deployed at:",
            address(newImplementation)
        );

        console.log(
            "DirectSalePool Proxy Admin:",
            Upgrades.getAdminAddress(PROXY_DIRECT_SALE_POOL)
        );
        console.log(
            "DirectSalePool upgraded before:",
            Upgrades.getImplementationAddress(PROXY_DIRECT_SALE_POOL)
        );

        // 加入初始化 data
        bytes memory data = abi.encodeCall(
            InvestorSalePool.initialize,
            (INITIAL_OWNER, FCC_ADDRESS, REDEMPT_POOL, USDT_ADDRESS)
        );

        Upgrades.upgradeProxy(
            PROXY_DIRECT_SALE_POOL,
            "InvestorSalePool.sol:InvestorSalePool",
            data,
            deployerAddress
        );
        console.log("InvestorSalePool proxy upgraded successfully");
        vm.stopBroadcast();

        console.log(
            "DirectSalePool upgraded after:",
            Upgrades.getImplementationAddress(PROXY_DIRECT_SALE_POOL)
        );
        console.log(
            "DirectSalePool Proxy Admin:",
            Upgrades.getAdminAddress(PROXY_DIRECT_SALE_POOL)
        );
    }
}
