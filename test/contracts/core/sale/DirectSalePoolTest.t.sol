// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console} from "forge-std/console.sol";

import {FishCakeCoin} from "@contracts/core/token/FishCakeCoin.sol";
import {IDirectSalePool} from "@contracts/interfaces/IDirectSalePool.sol";
import {FishcakeTestHelperTest} from "../../FishcakeTestHelper.t.sol";

contract DirectSalePoolTest is FishcakeTestHelperTest {

    function setUp() public virtual override {
        super.setUp();
    }

    function test_buyFccAmount() public {
        super.test_FishCakeCoin_PoolAllocate();

        FishCakeCoin tempFishCakeCoin = FishCakeCoin(address(proxyFishCakeCoin));
        IDirectSalePool tempDirectSalePool = IDirectSalePool(address(proxyDirectSalePool));

        uint256 before_tempDirectSalePool_fcc = tempFishCakeCoin.FccBalance(address(tempDirectSalePool));
        console.log("DirectSalePoolTest test_buyFccAmount before_tempDirectSalePool_fcc:", before_tempDirectSalePool_fcc);
        uint256 before_tempDirectSalePool_usdt = usdtToken.balanceOf(address(tempDirectSalePool));
        console.log("DirectSalePoolTest test_buyFccAmount before_tempDirectSalePool_usdt:", before_tempDirectSalePool_usdt);

        uint256 before_redemptionPool_fcc = tempFishCakeCoin.FccBalance(address(redemptionPool));
        console.log("DirectSalePoolTest test_buyFccAmount before_redemptionPool_fcc:", before_redemptionPool_fcc);
        uint256 before_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("DirectSalePoolTest test_buyFccAmount before_redemptionPool_usdt:", before_redemptionPool_usdt);

        uint256 before_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("DirectSalePoolTest test_buyFccAmount before_deployerAddress_fcc:", before_deployerAddress_fcc);
        uint256 before_deployerAddress_usdt = usdtToken.balanceOf(deployerAddress);
        console.log("DirectSalePoolTest test_buyFccAmount before_deployerAddress_usdt:", before_deployerAddress_usdt);

        uint256 fcc_amount = 1_000_000_000;

        vm.startBroadcast(deployerAddress);
        usdtToken.approve(address(tempDirectSalePool), fcc_amount);
        tempDirectSalePool.buyFccAmount(fcc_amount);
        vm.stopBroadcast();

        uint256 after_tempDirectSalePool_fcc = tempFishCakeCoin.FccBalance(address(tempDirectSalePool));
        console.log("DirectSalePoolTest test_buyFccAmount after_tempDirectSalePool_fcc:", after_tempDirectSalePool_fcc);
        assertTrue((before_tempDirectSalePool_fcc - fcc_amount) == after_tempDirectSalePool_fcc, "before_tempDirectSalePool_fcc - fcc_amount == after_tempDirectSalePool_fcc");

        uint256 after_tempDirectSalePool_usdt = usdtToken.balanceOf(address(tempDirectSalePool));
        console.log("DirectSalePoolTest test_buyFccAmount after_tempDirectSalePool_usdt:", after_tempDirectSalePool_usdt);
        assertTrue(after_tempDirectSalePool_usdt == 0, "after_tempDirectSalePool_usdt == 0");

        uint256 after_redemptionPool_fcc = tempFishCakeCoin.FccBalance(address(redemptionPool));
        console.log("DirectSalePoolTest test_buyFccAmount after_redemptionPool_fcc:", after_redemptionPool_fcc);
        assertTrue(after_redemptionPool_fcc == 0, "after_redemptionPool_fcc == 0");

        uint256 after_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("DirectSalePoolTest test_buyFccAmount after_redemptionPool_usdt:", after_redemptionPool_usdt);
        assertTrue(after_redemptionPool_usdt == (fcc_amount / 10), "buyFccAmount after_redemptionPool_usdt = fcc_amount / 10");

        uint256 after_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("DirectSalePoolTest test_buyFccAmount after_deployerAddress_fcc:", after_deployerAddress_fcc);
        assertTrue(after_deployerAddress_fcc == fcc_amount, "buyFccAmount after_deployerAddress_fcc = fcc_amount");

        uint256 after_deployerAddress_usdt = usdtToken.balanceOf(address(deployerAddress));
        console.log("DirectSalePoolTest test_buyFccAmount after_deployerAddress_usdt:", after_deployerAddress_usdt);
        assertTrue((before_deployerAddress_usdt - after_redemptionPool_usdt) == after_deployerAddress_usdt, "(before_deployerAddress_usdt - after_redemptionPool_usdt) == after_deployerAddress_usdt");
    }


    function test_buyFccByUsdtAmount() public {
        super.test_FishCakeCoin_PoolAllocate();

        FishCakeCoin tempFishCakeCoin = FishCakeCoin(address(proxyFishCakeCoin));
        IDirectSalePool tempDirectSalePool = IDirectSalePool(address(proxyDirectSalePool));

        uint256 before_tempDirectSalePool_fcc = tempFishCakeCoin.FccBalance(address(tempDirectSalePool));
        console.log("DirectSalePoolTest test_buyFccByUsdtAmount before_tempDirectSalePool_fcc:", before_tempDirectSalePool_fcc);

        uint256 before_tempDirectSalePool_usdt = usdtToken.balanceOf(address(tempDirectSalePool));
        console.log("DirectSalePoolTest test_buyFccByUsdtAmount before_tempDirectSalePool_usdt:", before_tempDirectSalePool_usdt);

        uint256 before_redemptionPool_fcc = tempFishCakeCoin.FccBalance(address(redemptionPool));
        console.log("DirectSalePoolTest test_buyFccByUsdtAmount before_redemptionPool_fcc:", before_redemptionPool_fcc);
        uint256 before_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("DirectSalePoolTest test_buyFccByUsdtAmount before_redemptionPool_usdt:", before_redemptionPool_usdt);

        uint256 before_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("DirectSalePoolTest test_buyFccByUsdtAmount before_deployerAddress_fcc:", before_deployerAddress_fcc);
        uint256 before_deployerAddress_usdt = usdtToken.balanceOf(deployerAddress);
        console.log("DirectSalePoolTest test_buyFccByUsdtAmount before_deployerAddress_usdt:", before_deployerAddress_usdt);

        uint256 usdt_amount = 10000;

        vm.startBroadcast(deployerAddress);
        usdtToken.approve(address(tempDirectSalePool), usdt_amount);
        tempDirectSalePool.buyFccByUsdtAmount(usdt_amount);
        vm.stopBroadcast();

        uint256 after_tempDirectSalePool_fcc = tempFishCakeCoin.FccBalance(address(tempDirectSalePool));
        console.log("DirectSalePoolTest test_buyFccByUsdtAmount after_tempDirectSalePool_fcc:", after_tempDirectSalePool_fcc);
        assertTrue(after_tempDirectSalePool_fcc == (before_tempDirectSalePool_fcc - (usdt_amount * 10)), "buyFccAmount after_tempDirectSalePool_fcc == (before_tempDirectSalePool_fcc - (usdt_amount * 10))");

        uint256 after_tempDirectSalePool_usdt = usdtToken.balanceOf(address(tempDirectSalePool));
        console.log("DirectSalePoolTest test_buyFccByUsdtAmount after_tempDirectSalePool_usdt:", after_tempDirectSalePool_usdt);
        assertTrue(after_tempDirectSalePool_usdt == 0, "buyFccAmount after_tempDirectSalePool_usdt is 0");

        uint256 after_redemptionPool_fcc = tempFishCakeCoin.FccBalance(address(redemptionPool));
        console.log("DirectSalePoolTest test_buyFccByUsdtAmount after_redemptionPool_fcc:", after_redemptionPool_fcc);
        assertTrue(after_redemptionPool_fcc == 0, "buyFccAmount after_redemptionPool_fcc is 0");

        uint256 after_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("DirectSalePoolTest test_buyFccByUsdtAmount after_redemptionPool_usdt:", after_redemptionPool_usdt);
        assertTrue(after_redemptionPool_usdt == usdt_amount, "buyFccAmount after_redemptionPool_usdt = usdt_amount");

        uint256 after_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("DirectSalePoolTest test_buyFccByUsdtAmount after_deployerAddress_fcc:", after_deployerAddress_fcc);
        assertTrue(after_deployerAddress_fcc == (usdt_amount * 10), "buyFccAmount after_deployerAddress_fcc = (usdt_amount * 10)");

        uint256 after_deployerAddress_usdt = usdtToken.balanceOf(address(deployerAddress));
        console.log("DirectSalePoolTest test_buyFccByUsdtAmount after_deployerAddress_usdt:", after_deployerAddress_usdt);
        assertTrue((before_deployerAddress_usdt - usdt_amount) == after_deployerAddress_usdt, "(before_deployerAddress_usdt - usdt_amount) == after_deployerAddress_usdt");

    }


}
