// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin-foundry-upgrades/Upgrades.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import "../src/contracts/core/sale/DirectSalePool.sol";
import "../src/contracts/core/token/NftManager.sol";
import "../src/contracts/core/FishcakeEventManager.sol";
import "../src/contracts/core/RedemptionPool.sol";
import "../src/contracts/core/sale/InvestorSalePool.sol";
import {FishCakeCoinStorage} from "@contracts/core/token/FishCakeCoinStorage.sol";

/*
forge script script/Deployer.s.sol:DeployerScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY  --broadcast -vvvv
*/
contract DeployerScript is Script {
//    ProxyAdmin public dapplinkProxyAdmin;

    RedemptionPool public redemptionPool;

    // ========= can upgrade ===========
    FishCakeCoin public fishCakeCoin;
    DirectSalePool public directSalePool;
    InvestorSalePool public investorSalePool;
    NftManager public nftManager;
    FishcakeEventManager public fishcakeEventManager;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        address usdtTokenAddress = vm.envAddress("USDT_ADDRESS");
        console.log("deploy deployerAddress:", address(deployerAddress));
//        dapplinkProxyAdmin = new ProxyAdmin(deployerAddress);

        vm.startBroadcast(deployerPrivateKey);

        fishCakeCoin = new FishCakeCoin();
        address proxyFishCakeCoin = Upgrades.deployTransparentProxy(
            "FishCakeCoin.sol:FishCakeCoin",
            deployerAddress,
            abi.encodeWithSelector(FishCakeCoin.initialize.selector, deployerAddress, address(0))
        );
        console.log("deploy proxyFishCakeCoin:", address(proxyFishCakeCoin));

        // can not upgrade
        redemptionPool = new RedemptionPool(address(proxyFishCakeCoin), usdtTokenAddress);
        console.log("deploy redemptionPool:", address(redemptionPool));

        directSalePool = new DirectSalePool();
        address proxyDirectSalePool = Upgrades.deployTransparentProxy(
            "DirectSalePool.sol:DirectSalePool",
            deployerAddress,
            abi.encodeWithSelector(DirectSalePool.initialize.selector, deployerAddress, proxyFishCakeCoin, redemptionPool, usdtTokenAddress)
        );
        console.log("deploy proxyDirectSalePool:", address(proxyDirectSalePool));

        investorSalePool = new InvestorSalePool();
        address proxyInvestorSalePool = Upgrades.deployTransparentProxy(
            "InvestorSalePool.sol:InvestorSalePool",
            deployerAddress,
            abi.encodeWithSelector(InvestorSalePool.initialize.selector, deployerAddress, proxyFishCakeCoin, redemptionPool, usdtTokenAddress)
        );
        console.log("deploy proxyInvestorSalePool:", address(proxyInvestorSalePool));

        nftManager = new NftManager();
        address proxyNftManager = Upgrades.deployTransparentProxy(
            "NftManager.sol:NftManager",
            deployerAddress,
            abi.encodeWithSelector(NftManager.initialize.selector, deployerAddress, proxyFishCakeCoin, usdtTokenAddress, redemptionPool)
        );
        console.log("deploy proxyNftManager:", address(proxyNftManager));
        console.log("deploy proxyNftManager fccTokenAddr :", address(NftManager(payable(address(proxyNftManager))).fccTokenAddr()));
        console.log("deploy proxyNftManager tokenUsdtAddr :", address(NftManager(payable(address(proxyNftManager))).tokenUsdtAddr()));
        console.log("deploy proxyNftManager redemptionPoolAddress :", address(NftManager(payable(address(proxyNftManager))).redemptionPoolAddress()));

        fishcakeEventManager = new FishcakeEventManager();
        address proxyFishcakeEventManager = Upgrades.deployTransparentProxy(
            "FishcakeEventManager.sol:FishcakeEventManager",
            deployerAddress,
            abi.encodeWithSelector(FishcakeEventManager.initialize.selector, deployerAddress, proxyFishCakeCoin, usdtTokenAddress, proxyNftManager)
        );
        console.log("deploy proxyFishcakeEventManager:", address(proxyFishcakeEventManager));

        // setUp
        FishCakeCoin(address(proxyFishCakeCoin)).setRedemptionPool(address(redemptionPool));
        IInvestorSalePool(address(proxyInvestorSalePool)).setValutAddress(deployerAddress);

        FishCakeCoinStorage.fishCakePool memory fishCakePool = FishCakeCoinStorage.fishCakePool({
            miningPool: address(proxyFishcakeEventManager),
            directSalePool: address(proxyDirectSalePool),
            investorSalePool: address(proxyInvestorSalePool),
            nftSalesRewardsPool: address(proxyNftManager),
            ecosystemPool: deployerAddress,
            foundationPool: deployerAddress,
            redemptionPool: address(redemptionPool)
        });
        FishCakeCoin(address(proxyFishCakeCoin)).setPoolAddress(fishCakePool);

        FishCakeCoin(address(proxyFishCakeCoin)).poolAllocate();

        (address miningPool, address directSalePool, address investorSalePool, address nftSalesRewardsPool,
            address ecosystemPool, address foundationPool, address redemptionPool) = FishCakeCoin(address(proxyFishCakeCoin)).fcPool();
        console.log("deploy fishCakePool miningPool:", miningPool);
        console.log("deploy fishCakePool directSalePool:", directSalePool);
        console.log("deploy fishCakePool investorSalePool:", investorSalePool);
        console.log("deploy fishCakePool nftSalesRewardsPool:", nftSalesRewardsPool);
        console.log("deploy fishCakePool ecosystemPool:", ecosystemPool);
        console.log("deploy fishCakePool foundationPool:", foundationPool);
        console.log("deploy fishCakePool redemptionPool:", redemptionPool);

        vm.stopBroadcast();
    }
}
