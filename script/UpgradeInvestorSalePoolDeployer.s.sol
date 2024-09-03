// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../src/contracts/core/sale/InvestorSalePool.sol";

contract UpgradeInvestorSalePoolDeployer is Script {
    // main net
    // address public constant PROXY_INVESTOR_SALE_POOL = address(0xaD5398b795763aB69FA66672Fffe4A245A5bA354);
    // address public constant DAPPLINK_PROXY_ADMIN = address(0x6a59e248FAe470F26D0C68ea447c8bfdcD15fE7b);
    // address public constant USDT = address(0xCbA6b93724394364cc679057959bE14430621aE7);
    //
    // address public OLD_PROXY_FISHCAKE_COIN = address(0xCE8bBFD5Af030F6b9f53AEdC72Fe55EDE5930236);
    // address public OLD_REDEMPTION_POOL = address(0x692F53439bf4656AB0F15fc1c2237b5cC96D36cE);

    // local
    address public constant PROXY_INVESTOR_SALE_POOL = address(0x0D8694F47cDC22Bb8C6D2668a38d07a439F378F9);
    address public constant DAPPLINK_PROXY_ADMIN = address(0x5094103dE460dF9BC1A0F2D69d6D6547cc97c050);
    address public constant USDT = address(0x3C4249f1cDf4C5Ee12D480a543a6A42362baAAFf);

    address public OLD_PROXY_FISHCAKE_COIN = address(0x1Cff7CDEcEF22D70FedefE1774831F18b86E9888);
    address public OLD_REDEMPTION_POOL = address(0x32e0a4F5c9846C8C504103E41d7E8EdF03CE8CBC);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // new InvestorSalePool
        InvestorSalePool newInvestorSalePool = new InvestorSalePool(
            OLD_PROXY_FISHCAKE_COIN, // proxyFishCakeCoin address
            OLD_REDEMPTION_POOL, // redemptionPool address
            USDT  // usdtTokenAddress
        );
        console.log("New InvestorSalePool implementation deployed at:", address(newInvestorSalePool));

        ProxyAdmin proxyAdmin = ProxyAdmin(DAPPLINK_PROXY_ADMIN);
        console.log("proxyAdmin  deployed at:", address(proxyAdmin));
        console.log("proxyAdmin owner deployed at:", proxyAdmin.owner());
        console.log("deployerAddress deployed at:", deployerAddress);
        require(proxyAdmin.owner() == deployerAddress, "Deployer is not the owner of ProxyAdmin");

        console.log("run 1 msg.sender deployed at:", msg.sender);

//        TransparentUpgradeableProxy proxyInvestorSalePool = new TransparentUpgradeableProxy(
//            address(newInvestorSalePool),
//            address(DAPPLINK_PROXY_ADMIN),
//            abi.encodeWithSelector(InvestorSalePool.initialize.selector, deployerAddress)
//        );

//        bytes memory data = abi.encodeWithSelector(newInvestorSalePool.initialize.selector, deployerAddress);
        bytes memory data = abi.encodeCall(newInvestorSalePool.initialize, deployerAddress);

        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(TransparentUpgradeableProxy(payable(PROXY_INVESTOR_SALE_POOL)))),
            address(newInvestorSalePool),
            data
        );

//        console.log("proxy deployed at:", address(proxyInvestorSalePool));
        console.log("run 2 msg.sender deployed at:", msg.sender);

//        proxyAdmin.upgradeAndCall(
//            ITransparentUpgradeableProxy(address(proxyInvestorSalePool)),
//            address(newInvestorSalePool),
//            ""
//        );

//        TransparentUpgradeableProxy proxy = TransparentUpgradeableProxy(payable(PROXY_INVESTOR_SALE_POOL));
//        console.log("proxy deployed at:", address(proxy));
//        console.log("run 2 msg.sender deployed at:", msg.sender);
//        ,
//        abi.encodeWithSelector(InvestorSalePool.initialize.selector, deployerAddress)
//        try
//        proxyAdmin.upgradeAndCall(
//            ITransparentUpgradeableProxy(address(proxy)),
//            address(newInvestorSalePool),
//            ""
//        );
//        ) {
//            console.log("InvestorSalePool proxy upgraded and initialized with new implementation");
//        } catch Error(string memory reason) {
//            console.log("Upgrade failed:", reason);
//        } catch (bytes memory lowLevelData) {
//            console.log("Upgrade failed with low-level error");
//        }

        console.log("InvestorSalePool proxy upgraded and initialized with new implementation");

        console.log("=======================================================================");
        console.log("=======================================================================");
        console.log("=======================================================================");
        console.log("dapplink_proxy_admin deployed at:", address(DAPPLINK_PROXY_ADMIN));
        console.log("owner deployed at:", address(deployerAddress));

        console.log("newInvestorSalePool implementation deployed at:", address(newInvestorSalePool));
        console.log("newInvestorSalePool proxy deployed at:", address(PROXY_INVESTOR_SALE_POOL));

        vm.stopBroadcast();
    }
}
