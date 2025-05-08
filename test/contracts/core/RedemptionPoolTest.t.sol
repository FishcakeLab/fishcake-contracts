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

    // In order to run a test case, the following code needs to be modified
    // change 1 before
    // uint256 public immutable unlockTime = block.timestamp + 1095 days;
    // change 1 after
    // uint256 public immutable unlockTime = block.timestamp;

    // change 2 before
    // require(block.timestamp > unlockTime, "RedemptionPool claim: redemption is locked");
    // change 2 after
    // require(block.timestamp >= unlockTime, "RedemptionPool claim: redemption is locked");
    function test_claim() external {
        FishCakeCoin tempFishCakeCoin = FishCakeCoin(address(proxyFishCakeCoin));
        test_buyFccAmount();

        console.log("RedemptionPoolTest test_claim block.timestamp:", block.timestamp);
        console.log("RedemptionPoolTest test_claim unlockTime:", redemptionPool.unlockTime());

        uint256 before_totalSupply = tempFishCakeCoin.totalSupply();
        console.log("RedemptionPoolTest test_claim before fcc totalSupply:", before_totalSupply);
        uint256 before_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("RedemptionPoolTest test_claim before_deployerAddress_fcc:", before_deployerAddress_fcc);
        uint256 before_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("RedemptionPoolTest test_claim before_redemptionPool_usdt:", before_redemptionPool_usdt);
        uint256 before_deployerAddress_usdt = usdtToken.balanceOf(address(deployerAddress));
        console.log("RedemptionPoolTest test_claim before_deployerAddress_usdt:", before_deployerAddress_usdt);

        vm.startPrank(deployerAddress);
        // uint256 temp_amount = 100_000_000;
        // redemptionPool.claim(temp_amount);
        vm.stopPrank();

//        uint256 after_totalSupply = tempFishCakeCoin.totalSupply();
//        console.log("RedemptionPoolTest test_claim after fcc totalSupply:", after_totalSupply);
//        assertTrue(after_totalSupply == (before_totalSupply - temp_amount), "after_totalSupply == (before_totalSupply - temp_amount)");
//
//        uint256 after_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
//        console.log("RedemptionPoolTest test_claim after_deployerAddress_fcc:", after_deployerAddress_fcc);
//        assertTrue(after_deployerAddress_fcc == (before_deployerAddress_fcc - temp_amount), "after_deployerAddress_fcc == (before_deployerAddr");
//
//        uint256 temp_result = before_redemptionPool_usdt * temp_amount / before_totalSupply;
//        console.log("RedemptionPoolTest test_claim temp_result:", temp_result);
//
//        uint256 after_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
//        console.log("RedemptionPoolTest test_claim after_redemptionPool_usdt:", after_redemptionPool_usdt);
//        assertTrue(after_redemptionPool_usdt == (before_redemptionPool_usdt - temp_result), "after_redemptionPool_usdt == (before_redemptionPool_usdt - temp_result)");
//
//        uint256 after_deployerAddress_usdt = usdtToken.balanceOf(address(deployerAddress));
//        console.log("RedemptionPoolTest test_claim after_deployerAddress_usdt:", after_deployerAddress_usdt);
//        assertTrue(after_deployerAddress_usdt == (before_deployerAddress_usdt + temp_result), "after_deployerAddress_usdt == (before_deployerAddress_usdt + temp_result)");
    }
}
