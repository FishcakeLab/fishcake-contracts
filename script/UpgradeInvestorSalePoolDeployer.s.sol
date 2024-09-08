//// SPDX-License-Identifier: UNLICENSED
//pragma solidity ^0.8.0;
//
//import {Script} from "forge-std/Script.sol";
//import {console} from "forge-std/console.sol";
//
//import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
//import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
//
//import "../src/contracts/core/sale/InvestorSalePool.sol";
//
//contract UpgradeInvestorSalePoolDeployer is Script {
//    // main net
//    // address public constant PROXY_INVESTOR_SALE_POOL = address(0xaD5398b795763aB69FA66672Fffe4A245A5bA354);
//    //
//    // address public OLD_PROXY_FISHCAKE_COIN = address(0xCE8bBFD5Af030F6b9f53AEdC72Fe55EDE5930236);
//    // address public OLD_REDEMPTION_POOL = address(0x692F53439bf4656AB0F15fc1c2237b5cC96D36cE);
//
//    // local
//    address public constant PROXY_INVESTOR_SALE_POOL = address(0x547C22E900813Bb331893878CD3bfe7171E4702F);
//
//    address public OLD_PROXY_FISHCAKE_COIN = address(0xb3e2864c9FF44E2B4d1EC8aA84a169D8bCb511c8);
//    address public OLD_REDEMPTION_POOL = address(0xB8A6dd862133A4C20FAa722EA683334D1E194AB1);
//
//    function run() public {
//        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//        address deployerAddress = vm.addr(deployerPrivateKey);
//
//        address usdtTokenAddress = vm.envAddress("USDT_ADDRESS");
//
//        // new InvestorSalePool
//        InvestorSalePool newInvestorSalePool = new InvestorSalePool(
//            OLD_PROXY_FISHCAKE_COIN, // proxyFishCakeCoin address
//            OLD_REDEMPTION_POOL, // redemptionPool address
//            usdtTokenAddress  // usdtTokenAddress
//        );
//        console.log("New InvestorSalePool implementation deployed at:", address(newInvestorSalePool));
//
//        ProxyAdmin proxyAdmin = new ProxyAdmin(deployerAddress);
//        console.log("proxyAdmin  deployed at:", address(proxyAdmin));
//        console.log("proxyAdmin owner deployed at:", proxyAdmin.owner());
//        console.log("deployerAddress deployed at:", deployerAddress);
//        require(proxyAdmin.owner() == deployerAddress, "Deployer is not the owner of ProxyAdmin");
//
//        console.log("run 1 msg.sender deployed at:", msg.sender);
//
//        vm.startBroadcast(deployerPrivateKey);
//        bytes memory data = abi.encodeCall(newInvestorSalePool.initialize, deployerAddress);
//
//        proxyAdmin.upgradeAndCall(
//            ITransparentUpgradeableProxy(address(TransparentUpgradeableProxy(payable(PROXY_INVESTOR_SALE_POOL)))),
//            address(newInvestorSalePool),
//            data
//        );
//        vm.stopBroadcast();
//
//        console.log("run 2 msg.sender deployed at:", msg.sender);
//
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
