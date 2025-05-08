// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin-foundry-upgrades/Upgrades.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import "../src/contracts/core/sale/DirectSalePool.sol";
import {NftManagerV3 as NftManager} from "../src/contracts/core/token/NftManagerV3.sol";
import "../src/contracts/core/FishcakeEventManager.sol";
import "../src/contracts/core/RedemptionPool.sol";
import "../src/contracts/core/sale/InvestorSalePool.sol";
import {FishCakeCoinStorage} from "@contracts/core/token/FishCakeCoinStorage.sol";

/*
forge script script/Deployer.s.sol:DeployerScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY  --broadcast -vvvv
*/
contract DeployerV4Script is Script {
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
        console.log("deploy deployerAddress:", address(deployerAddress));
        address usdtTokenAddress = vm.envAddress("USDT_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);
        // 1. 部署 FishCakeCoin 合约
        fishCakeCoin = new FishCakeCoin();
        address proxyFishCakeCoin = Upgrades.deployTransparentProxy(
            "FishCakeCoin.sol:FishCakeCoin",
            deployerAddress,
            abi.encodeWithSelector(FishCakeCoin.initialize.selector, deployerAddress, address(0))
        );
        console.log("deploy proxyFishCakeCoin:", address(proxyFishCakeCoin));

        // 2. 部署 RedemptionPool 合约
        redemptionPool = new RedemptionPool(address(proxyFishCakeCoin), usdtTokenAddress);
        console.log("deploy redemptionPool:", address(redemptionPool));

        // 3. 部署 DirectSalePool 合约
        directSalePool = new DirectSalePool();
        address proxyDirectSalePool = Upgrades.deployTransparentProxy(
            "DirectSalePool.sol:DirectSalePool",
            deployerAddress,
            abi.encodeWithSelector(DirectSalePool.initialize.selector, deployerAddress, proxyFishCakeCoin, redemptionPool, usdtTokenAddress)
        );
        console.log("deploy proxyDirectSalePool:", address(proxyDirectSalePool));

        // 4. 部署 InvestorSalePool 合约
        investorSalePool = new InvestorSalePool();
        address proxyInvestorSalePool = Upgrades.deployTransparentProxy(
            "InvestorSalePool.sol:InvestorSalePool",
            deployerAddress,
            abi.encodeWithSelector(InvestorSalePool.initialize.selector, deployerAddress, proxyFishCakeCoin, redemptionPool, usdtTokenAddress)
        );
        console.log("deploy proxyInvestorSalePool:", address(proxyInvestorSalePool));

        // 5. 部署 NftManager 合约
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

        // 6. 部署 FishcakeEventManager 合约
        fishcakeEventManager = new FishcakeEventManager();
        address proxyFishcakeEventManager = Upgrades.deployTransparentProxy(
            "FishcakeEventManager.sol:FishcakeEventManager",
            deployerAddress,
            abi.encodeWithSelector(FishcakeEventManager.initialize.selector, deployerAddress, proxyFishCakeCoin, usdtTokenAddress, proxyNftManager)
        );
        console.log("deploy proxyFishcakeEventManager:", address(proxyFishcakeEventManager));

        // setUp
        FishCakeCoin(address(proxyFishCakeCoin)).setRedemptionPool(address(redemptionPool));
        IInvestorSalePool(address(proxyInvestorSalePool)).setVaultAddress(deployerAddress);

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

        (address miningPool, address directSalePoolAddress, address investorSalePoolAddress, address nftSalesRewardsPool,
            address ecosystemPool, address foundationPool, address redemptionPoolAddress) = FishCakeCoin(address(proxyFishCakeCoin)).fcPool();
        console.log("deploy fishCakePool miningPool:", miningPool);
        console.log("deploy fishCakePool directSalePool:", directSalePoolAddress);
        console.log("deploy fishCakePool investorSalePool:", investorSalePoolAddress);
        console.log("deploy fishCakePool nftSalesRewardsPool:", nftSalesRewardsPool);
        console.log("deploy fishCakePool ecosystemPool:", ecosystemPool);
        console.log("deploy fishCakePool foundationPool:", foundationPool);
        console.log("deploy fishCakePool redemptionPool:", redemptionPoolAddress);

        vm.stopBroadcast();
    }
}
