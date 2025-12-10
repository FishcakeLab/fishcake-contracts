// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console} from "forge-std/console.sol";

import {FishcakeDeployerTest} from "./FishcakeDeployerTest.t.sol";
import {FishCakeCoin} from "@contracts/core/token/FishCakeCoin.sol";
import {FishCakeCoinStorage} from "@contracts/core/token/FishCakeCoinStorage.sol";

contract FishcakeTestHelperTest is FishcakeDeployerTest {
    //    address internal constant MINING_POOL = address(0x1);
    //    address internal constant DIRECT_SALE_POOL = address(0x2);
    //    address internal constant INVESTOR_SALE_POOL = address(0x3);
    //    address internal constant NFTSALES_REWARDS_POOL = address(0x4);
    address internal constant ECOSYSTEM_POOL = address(0x5);
    address internal constant FOUNDATION_POOL = address(0x6);

    //    address internal constant REDEMPTION_POOL = address(0x7);

    function test_FishCakeCoin_PoolAllocate() public {
        FishCakeCoin tempFishCakeCoin = FishCakeCoin(
            address(proxyFishCakeCoin)
        );

        FishCakeCoinStorage.fishCakePool
            memory fishCakePool = FishCakeCoinStorage.fishCakePool({
                miningPool: address(proxyFishcakeEventManager),
                directSalePool: address(proxyDirectSalePool),
                investorSalePool: address(proxyInvestorSalePool),
                nftSalesRewardsPool: address(proxyNftManagerV5),
                ecosystemPool: ECOSYSTEM_POOL,
                foundationPool: FOUNDATION_POOL,
                redemptionPool: address(redemptionPool)
            });

        vm.startBroadcast(deployerAddress);
        tempFishCakeCoin.setPoolAddress(fishCakePool);
        tempFishCakeCoin.poolAllocate();
        vm.stopBroadcast();

        assertTrue(
            6 == tempFishCakeCoin.decimals(),
            "fishCakeCoin decimals is 6"
        );

        uint256 deployerAddress_balance = tempFishCakeCoin.balanceOf(
            deployerAddress
        );
        console.log(
            "FishCakeCoin test_PoolAllocate deployerAddress_balance:",
            deployerAddress_balance
        );
        uint256 usdtTokenAddress_balance = tempFishCakeCoin.balanceOf(
            address(usdtToken)
        );
        console.log(
            "FishCakeCoin test_PoolAllocate usdtTokenAddress_balance:",
            usdtTokenAddress_balance
        );

        uint256 MINING_POOL_balance = tempFishCakeCoin.balanceOf(
            address(proxyFishcakeEventManager)
        );
        console.log(
            "FishCakeCoin test_PoolAllocate MINING_POOL_balance:",
            MINING_POOL_balance
        );
        assertTrue(
            (tempFishCakeCoin.MaxTotalSupply() * 3) / 10 == MINING_POOL_balance,
            "MINING_POOL_balance is 300000000000000"
        );

        uint256 DIRECT_SALE_POOL_balance = tempFishCakeCoin.balanceOf(
            address(proxyDirectSalePool)
        );
        console.log(
            "FishCakeCoin test_PoolAllocate DIRECT_SALE_POOL_balance:",
            DIRECT_SALE_POOL_balance
        );
        assertTrue(
            (tempFishCakeCoin.MaxTotalSupply() * 2) / 10 ==
                DIRECT_SALE_POOL_balance,
            "DIRECT_SALE_POOL_balance is 200000000000000"
        );

        uint256 INVESTOR_SALE_POOL_balance = tempFishCakeCoin.balanceOf(
            address(proxyInvestorSalePool)
        );
        console.log(
            "FishCakeCoin test_PoolAllocate INVESTOR_SALE_POOL_balance:",
            INVESTOR_SALE_POOL_balance
        );
        assertTrue(
            (tempFishCakeCoin.MaxTotalSupply() * 1) / 10 ==
                INVESTOR_SALE_POOL_balance,
            "INVESTOR_SALE_POOL_balance is 100000000000000"
        );

        uint256 NFTSALES_REWARDS_POOL_balance = tempFishCakeCoin.balanceOf(
            address(proxyNftManagerV5)
        );
        console.log(
            "FishCakeCoin test_PoolAllocate NFTSALES_REWARDS_POOL_balance:",
            NFTSALES_REWARDS_POOL_balance
        );
        assertTrue(
            (tempFishCakeCoin.MaxTotalSupply() * 2) / 10 ==
                NFTSALES_REWARDS_POOL_balance,
            "NFTSALES_REWARDS_POOL_balance is 200000000000000"
        );

        uint256 ECOSYSTEM_POOL_balance = tempFishCakeCoin.balanceOf(
            ECOSYSTEM_POOL
        );
        console.log(
            "FishCakeCoin test_PoolAllocate ECOSYSTEM_POOL_balance:",
            ECOSYSTEM_POOL_balance
        );
        assertTrue(
            (tempFishCakeCoin.MaxTotalSupply() * 1) / 10 ==
                ECOSYSTEM_POOL_balance,
            "ECOSYSTEM_POOL_balance is 100000000000000"
        );

        uint256 FOUNDATION_POOL_balance = tempFishCakeCoin.balanceOf(
            FOUNDATION_POOL
        );
        console.log(
            "FishCakeCoin test_PoolAllocate FOUNDATION_POOL_balance:",
            FOUNDATION_POOL_balance
        );
        assertTrue(
            (tempFishCakeCoin.MaxTotalSupply() * 1) / 10 ==
                FOUNDATION_POOL_balance,
            "FOUNDATION_POOL_balance is 100000000000000"
        );

        uint256 REDEMPTION_POOL_balance = tempFishCakeCoin.balanceOf(
            address(redemptionPool)
        );
        console.log(
            "FishCakeCoin test_PoolAllocate REDEMPTION_POOL_balance:",
            REDEMPTION_POOL_balance
        );
        assertTrue(
            (tempFishCakeCoin.MaxTotalSupply() * 0) / 10 ==
                REDEMPTION_POOL_balance,
            "REDEMPTION_POOL_balance is 0"
        );

        uint256 tempTotalSupply = tempFishCakeCoin.totalSupply();
        console.log(
            "FishCakeCoin test_PoolAllocate tempTotalSupply:",
            tempTotalSupply
        );
        assertTrue(
            tempFishCakeCoin.MaxTotalSupply() == tempTotalSupply,
            "tempTotalSupply is 1000000000000000"
        );

        uint256 MINING_POOL_fcc_balance = tempFishCakeCoin.FccBalance(
            address(proxyFishcakeEventManager)
        );
        assertTrue(
            ((tempFishCakeCoin.MaxTotalSupply() * 3) / 10) ==
                MINING_POOL_fcc_balance,
            "MINING_POOL_fcc_balance is 300000000000000"
        );
    }
}
