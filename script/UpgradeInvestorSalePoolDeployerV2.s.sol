//// SPDX-License-Identifier: UNLICENSED
//pragma solidity ^0.8.0;
//
//import {Script} from "forge-std/Script.sol";
//import {console} from "forge-std/console.sol";
//
//import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
//import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
//import "@openzeppelin-foundry-upgrades/Upgrades.sol";
//
//import {InvestorSalePoolV2} from "../src/contracts/core/sale/InvestorSalePoolV2.sol";
//
//contract UpgradeInvestorSalePoolDeployer is Script {
//    // main net
//    // address public constant PROXY_INVESTOR_SALE_POOL = address(0xaD5398b795763aB69FA66672Fffe4A245A5bA354);
//    //
//    // address public OLD_PROXY_FISHCAKE_COIN = address(0xCE8bBFD5Af030F6b9f53AEdC72Fe55EDE5930236);
//    // address public OLD_REDEMPTION_POOL = address(0x692F53439bf4656AB0F15fc1c2237b5cC96D36cE);
//
//    // local
//    address public constant PROXY_INVESTOR_SALE_POOL = address(0xae646B445f556266003803558CB862bec1d8e271);
//
//    address public OLD_PROXY_FISHCAKE_COIN = address(0xDb91C3a7d3bF428d6E6e4Ba93bC2b1f8096606D3);
//    address public OLD_REDEMPTION_POOL = address(0x8a46B53Ba1488Fa6435BdE5f8dD4855f7eE60279);
//
//    function run() public {
//        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//        address deployerAddress = vm.addr(deployerPrivateKey);
//
//        address usdtTokenAddress = vm.envAddress("USDT_ADDRESS");
//
//        // new InvestorSalePool
//        InvestorSalePoolV2 newInvestorSalePool = new InvestorSalePoolV2();
//        console.log("New InvestorSalePool implementation deployed at:", address(newInvestorSalePool));
//
//        console.log("run 1 msg.sender deployed at:", msg.sender);
//        vm.startBroadcast(deployerPrivateKey);
////        bytes memory data = abi.encodeCall(newInvestorSalePool.initialize, (deployerAddress, OLD_PROXY_FISHCAKE_COIN, OLD_REDEMPTION_POOL, usdtTokenAddress));
//
//        Upgrades.upgradeProxy(
//            PROXY_INVESTOR_SALE_POOL,
//            "InvestorSalePoolV2.sol",
//            ""
//        );
//        vm.stopBroadcast();
//
//        console.log("run 2 msg.sender deployed at:", msg.sender);
//        console.log("InvestorSalePool proxy upgraded and initialized with new implementation");
//        console.log("=======================================================================");
//        console.log("=======================================================================");
//        console.log("=======================================================================");
//        console.log("owner deployed at:", address(deployerAddress));
//        console.log("newInvestorSalePool implementation deployed at:", address(newInvestorSalePool));
//        console.log("newInvestorSalePool proxy deployed at:", address(PROXY_INVESTOR_SALE_POOL));
//
//    }
//}
