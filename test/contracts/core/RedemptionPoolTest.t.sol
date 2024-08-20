// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";

import {FishcakeTestHelperTest} from "../FishcakeTestHelper.t.sol";
import {FishCakeCoin} from "@contracts/core/token/FishCakeCoin.sol";
import {RedemptionPool} from "@contracts/core/RedemptionPool.sol";
import {DirectSalePoolTest} from "./sale/DirectSalePoolTest.t.sol";

contract RedemptionPoolTest is DirectSalePoolTest {

    function setUp() public virtual override {
        super.setUp();
    }

    // 由于时间锁的存在，需要修改代码才可以测试
    // 修改前 uint256 public immutable unlockTime = block.timestamp + 1095 days;
    // 修改后 uint256 public immutable unlockTime = block.timestamp;

    // 修改前 require(block.timestamp > unlockTime, "RedemptionPool claim: redemption is locked");
    // 修改后 require(block.timestamp >= unlockTime, "RedemptionPool claim: redemption is locked");
    function test_claim() external {
        FishCakeCoin tempFishCakeCoin = FishCakeCoin(address(proxyFishCakeCoin));
        test_buyFccAmount();

        console.log("RedemptionPoolTest test_claim block.timestamp:", block.timestamp);
        console.log("RedemptionPoolTest test_claim unlockTime:", redemptionPool.unlockTime());

        console.log("RedemptionPoolTest test_claim before fcc totalSupply:", tempFishCakeCoin.totalSupply());
        uint256 before_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("RedemptionPoolTest test_claim before_deployerAddress_fcc:", before_deployerAddress_fcc);
        uint256 before_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("RedemptionPoolTest test_claim before_redemptionPool_usdt:", before_redemptionPool_usdt);
        uint256 before_deployerAddress_usdt = usdtToken.balanceOf(address(deployerAddress));
        console.log("RedemptionPoolTest test_claim before_deployerAddress_usdt:", before_deployerAddress_usdt);

        vm.startPrank(deployerAddress);
        redemptionPool.claim(100_000_000);
        vm.stopPrank();

        console.log("RedemptionPoolTest test_claim after fcc totalSupply:", tempFishCakeCoin.totalSupply());
        uint256 after_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("RedemptionPoolTest test_claim after_deployerAddress_fcc:", after_deployerAddress_fcc);
        uint256 after_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("RedemptionPoolTest test_claim after_redemptionPool_usdt:", after_redemptionPool_usdt);
        uint256 after_deployerAddress_usdt = usdtToken.balanceOf(address(deployerAddress));
        console.log("RedemptionPoolTest test_claim after_deployerAddress_usdt:", after_deployerAddress_usdt);
    }
}
