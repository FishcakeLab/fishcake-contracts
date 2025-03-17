// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console} from "forge-std/console.sol";

import {FishCakeCoin} from "@contracts/core/token/FishCakeCoin.sol";
import {InvestorSalePool} from "@contracts/core/sale/InvestorSalePool.sol";
import {InvestorSalePoolStorage} from "@contracts/core/sale/InvestorSalePoolStorage.sol";
import {IInvestorSalePool} from "@contracts/interfaces/IInvestorSalePool.sol";
import {FishcakeTestHelperTest} from "../../FishcakeTestHelper.t.sol";
import {MockInvestorSalePool} from "./MockInvestorSalePool.sol";

contract InvestorSalePoolTest is FishcakeTestHelperTest {

    function setUp() public virtual override {
        super.setUp();
    }

    function test_buyFccAmount() public {
        super.test_FishCakeCoin_PoolAllocate();

        FishCakeCoin tempFishCakeCoin = FishCakeCoin(address(proxyFishCakeCoin));
        InvestorSalePool tempInvestorSalePool = InvestorSalePool(address(proxyInvestorSalePool));

        uint256 before_tempInvestorSalePool_fcc = tempFishCakeCoin.FccBalance(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_buyFccAmount before_tempInvestorSalePool_fcc:", before_tempInvestorSalePool_fcc);
        uint256 before_tempInvestorSalePool_usdt = usdtToken.balanceOf(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_buyFccAmount before_tempInvestorSalePool_usdt:", before_tempInvestorSalePool_usdt);

        uint256 before_redemptionPool_fcc = tempFishCakeCoin.FccBalance(address(redemptionPool));
        console.log("InvestorSalePoolTest test_buyFccAmount before_redemptionPool_fcc:", before_redemptionPool_fcc);
        uint256 before_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("InvestorSalePoolTest test_buyFccAmount before_redemptionPool_usdt:", before_redemptionPool_usdt);

        uint256 before_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("InvestorSalePoolTest test_buyFccAmount before_deployerAddress_fcc:", before_deployerAddress_fcc);
        uint256 before_deployerAddress_usdt = usdtToken.balanceOf(deployerAddress);
        console.log("InvestorSalePoolTest test_buyFccAmount before_deployerAddress_usdt:", before_deployerAddress_usdt);

        uint256 fcc_amount = 16_666 * tempInvestorSalePool.fccDecimal();
        vm.startBroadcast(deployerAddress);
        usdtToken.approve(address(tempInvestorSalePool), fcc_amount);
        tempInvestorSalePool.buyFccAmount(fcc_amount);
        vm.stopBroadcast();

        MockInvestorSalePool mockPool = new MockInvestorSalePool();
        uint256 temp_usdt = mockPool.calculateUsdtByFcc_mock(fcc_amount);

        console.log("InvestorSalePoolTest test_buyFccAmount fcc_amount:", fcc_amount);
        console.log("InvestorSalePoolTest test_buyFccAmount temp_usdt:", temp_usdt);

        uint256 after_tempInvestorSalePool_fcc = tempFishCakeCoin.FccBalance(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_buyFccAmount after_tempInvestorSalePool_fcc:", after_tempInvestorSalePool_fcc);
        assertTrue(after_tempInvestorSalePool_fcc == before_tempInvestorSalePool_fcc - fcc_amount, "after_tempInvestorSalePool_fcc == before_tempInvestorSalePool_fcc - fcc_amount");

        uint256 after_tempInvestorSalePool_usdt = usdtToken.balanceOf(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_buyFccAmount after_tempInvestorSalePool_usdt:", after_tempInvestorSalePool_usdt);
        assertTrue(after_tempInvestorSalePool_usdt == (temp_usdt / 2), "after_tempInvestorSalePool_usdt == (temp_usdt / 2)");

        uint256 after_redemptionPool_fcc = tempFishCakeCoin.FccBalance(address(redemptionPool));
        console.log("InvestorSalePoolTest test_buyFccAmount after_redemptionPool_fcc:", after_redemptionPool_fcc);
        assertTrue(after_redemptionPool_fcc == 0, "after_redemptionPool_fcc == 0");

        uint256 after_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("InvestorSalePoolTest test_buyFccAmount after_redemptionPool_usdt:", after_redemptionPool_usdt);
        assertTrue(after_redemptionPool_usdt == (temp_usdt / 2), "after_redemptionPool_usdt == (temp_usdt / 2)");

        uint256 after_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("InvestorSalePoolTest test_buyFccAmount after_deployerAddress_fcc:", after_deployerAddress_fcc);
        assertTrue(after_deployerAddress_fcc == fcc_amount, "after_deployerAddress_fcc == fcc_amount");

        uint256 after_deployerAddress_usdt = usdtToken.balanceOf(deployerAddress);
        console.log("InvestorSalePoolTest test_buyFccAmount after_deployerAddress_usdt:", after_deployerAddress_usdt);
        assertTrue(after_deployerAddress_usdt == (before_deployerAddress_usdt - temp_usdt), "after_deployerAddress_usdt == (before_deployerAddress_usdt - temp_usdt)");
    }

    function test_buyFccByUsdtAmount() public {
        super.test_FishCakeCoin_PoolAllocate();

        FishCakeCoin tempFishCakeCoin = FishCakeCoin(address(proxyFishCakeCoin));
        InvestorSalePool tempInvestorSalePool = InvestorSalePool(address(proxyInvestorSalePool));

        uint256 before_tempInvestorSalePool_fcc = tempFishCakeCoin.FccBalance(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount before_tempInvestorSalePool_fcc:", before_tempInvestorSalePool_fcc);
        uint256 before_tempInvestorSalePool_usdt = usdtToken.balanceOf(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount before_tempInvestorSalePool_usdt:", before_tempInvestorSalePool_usdt);
        uint256 before_redemptionPool_fcc = tempFishCakeCoin.FccBalance(address(redemptionPool));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount before_redemptionPool_fcc:", before_redemptionPool_fcc);
        uint256 before_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount before_redemptionPool_usdt:", before_redemptionPool_usdt);
        uint256 before_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount before_deployerAddress_fcc:", before_deployerAddress_fcc);
        uint256 before_deployerAddress_usdt = usdtToken.balanceOf(deployerAddress);
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount before_deployerAddress_usdt:", before_deployerAddress_usdt);

        uint256 usdt_amount = 1_000 * tempInvestorSalePool.usdtDecimal();

        vm.startBroadcast(deployerAddress);
        usdtToken.approve(address(tempInvestorSalePool), usdt_amount);
        tempInvestorSalePool.buyFccByUsdtAmount(usdt_amount);
        vm.stopBroadcast();

        MockInvestorSalePool mockPool = new MockInvestorSalePool();
        uint256 temp_fcc = mockPool.calculateFccByUsdt_mock(usdt_amount);

        console.log("InvestorSalePoolTest test_buyFccAmount usdt_amount:", usdt_amount);
        console.log("InvestorSalePoolTest test_buyFccAmount temp_fcc:", temp_fcc);

        uint256 after_tempInvestorSalePool_fcc = tempFishCakeCoin.FccBalance(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount after_tempInvestorSalePool_fcc:", after_tempInvestorSalePool_fcc);
        assertTrue(after_tempInvestorSalePool_fcc == (before_tempInvestorSalePool_fcc - temp_fcc), "after_tempInvestorSalePool_fcc == (before_tempInvestorSalePool_fcc - temp_fcc)");

        uint256 after_tempInvestorSalePool_usdt = usdtToken.balanceOf(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount after_tempInvestorSalePool_usdt:", after_tempInvestorSalePool_usdt);
        assertTrue(after_tempInvestorSalePool_usdt == (usdt_amount / 2), "after_tempInvestorSalePool_usdt == (usdt_amount / 2)");

        uint256 after_redemptionPool_fcc = tempFishCakeCoin.FccBalance(address(redemptionPool));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount after_redemptionPool_fcc:", after_redemptionPool_fcc);
        assertTrue(after_redemptionPool_fcc == 0, "after_redemptionPool_fcc == 0");

        uint256 after_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount after_redemptionPool_usdt:", after_redemptionPool_usdt);
        assertTrue(after_redemptionPool_usdt == (usdt_amount / 2), "after_redemptionPool_usdt == (usdt_amount / 2)");

        uint256 after_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount after_deployerAddress_fcc:", after_deployerAddress_fcc);
        assertTrue(after_deployerAddress_fcc == temp_fcc, "after_deployerAddress_fcc == temp_fcc");

        uint256 after_deployerAddress_usdt = usdtToken.balanceOf(address(deployerAddress));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount after_deployerAddress_usdt:", after_deployerAddress_usdt);
        assertTrue(after_deployerAddress_usdt == (before_deployerAddress_usdt - usdt_amount), "after_deployerAddress_usdt == (before_deployerAddress_usdt - usdt_amount)");

    }

    function test_withdrawUsdt() public {
        FishCakeCoin tempFishCakeCoin = FishCakeCoin(address(proxyFishCakeCoin));
        IInvestorSalePool tempInvestorSalePool = IInvestorSalePool(address(proxyInvestorSalePool));

        vm.startBroadcast(deployerAddress);
        tempInvestorSalePool.setVaultAddress(deployerAddress);
        vm.stopBroadcast();

        test_buyFccByUsdtAmount();

        uint256 before_tempInvestorSalePool_fcc = tempFishCakeCoin.FccBalance(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_withdrawUsdt before_tempInvestorSalePool_fcc:", before_tempInvestorSalePool_fcc);
        uint256 before_tempInvestorSalePool_usdt = usdtToken.balanceOf(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_withdrawUsdt before_tempInvestorSalePool_usdt:", before_tempInvestorSalePool_usdt);

        uint256 before_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("InvestorSalePoolTest test_withdrawUsdt before_deployerAddress_fcc:", before_deployerAddress_fcc);
        uint256 before_deployerAddress_usdt = usdtToken.balanceOf(address(deployerAddress));
        console.log("InvestorSalePoolTest test_withdrawUsdt before_deployerAddress_usdt:", before_deployerAddress_usdt);

        uint256 temp_amount = 1000;
        vm.startPrank(deployerAddress);
        tempInvestorSalePool.withdrawUsdt(temp_amount);
        vm.stopPrank();

        uint256 after_tempInvestorSalePool_fcc = tempFishCakeCoin.FccBalance(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_withdrawUsdt after_tempInvestorSalePool_fcc:", after_tempInvestorSalePool_fcc);
        assertTrue(after_tempInvestorSalePool_fcc == before_tempInvestorSalePool_fcc, "after_tempInvestorSalePool_fcc = before_tempInvestorSalePool_fcc");

        uint256 after_tempInvestorSalePool_usdt = usdtToken.balanceOf(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_withdrawUsdt after_tempInvestorSalePool_usdt:", after_tempInvestorSalePool_usdt);
        assertTrue(after_tempInvestorSalePool_usdt == (before_tempInvestorSalePool_usdt - temp_amount), "after_tempInvestorSalePool_usdt = (before_tempInvestorSalePool_usdt - temp_amount)");

        uint256 after_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("InvestorSalePoolTest test_withdrawUsdt after_deployerAddress_fcc:", after_deployerAddress_fcc);
        assertTrue(after_deployerAddress_fcc == before_deployerAddress_fcc, "after_deployerAddress_fcc = before_deployerAddress_fcc");

        uint256 after_deployerAddress_usdt = usdtToken.balanceOf(address(deployerAddress));
        console.log("InvestorSalePoolTest test_withdrawUsdt after_deployerAddress_usdt:", after_deployerAddress_usdt);
        assertTrue(after_deployerAddress_usdt == (before_deployerAddress_usdt + temp_amount), "after_deployerAddress_usdt = (before_deployerAddress_usdt + temp_amount)");

    }

    function test_calculateFccByUsdt() public {
        // The denominator is expanded by a factor of 100
        uint256 constant_decimal = 1e2;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt constant_decimal:", constant_decimal);

        MockInvestorSalePool mockPool = new MockInvestorSalePool();

        console.log("InvestorSalePoolTest test_calculateFccByUsdt usdtDecimal:", mockPool.getUsdtDecimal_mock());
        console.log("InvestorSalePoolTest test_calculateFccByUsdt fccDecimal:", mockPool.getFccDecimal_mock());

        uint256 USDT_DECIMAL = mockPool.getUsdtDecimal_mock();

        uint256 test_1_usdt_input = 100_000 * USDT_DECIMAL;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_1_usdt_input:", test_1_usdt_input);
        uint256 test_1_fcc = mockPool.calculateFccByUsdt_mock(test_1_usdt_input);
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_1_fcc:", test_1_fcc);
        uint256 test_1_div = (test_1_usdt_input * constant_decimal) / test_1_fcc;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_1_div:", test_1_div);
        assertEq(test_1_div, 6, "test_1_div == 6");

        uint256 test_2_usdt_input = 10_000 * USDT_DECIMAL;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_2_usdt_input:", test_2_usdt_input);
        uint256 test_2_fcc = mockPool.calculateFccByUsdt_mock(test_2_usdt_input);
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_2_fcc:", test_2_fcc);
        uint256 test_2_div = (test_2_usdt_input * constant_decimal) / test_2_fcc;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_2_div:", test_2_div);
        assertTrue(test_2_div == 7, "test_2_div == 7");

        uint256 test_3_usdt_input = 5_000 * USDT_DECIMAL;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_3_usdt_input:", test_3_usdt_input);
        uint256 test_3_fcc = mockPool.calculateFccByUsdt_mock(test_3_usdt_input);
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_3_fcc:", test_3_fcc);
        uint256 test_3_div = (test_3_usdt_input * constant_decimal) / test_3_fcc;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_3_div:", test_3_div);
        assertTrue(test_3_div == 8, "test_3_div == 8");

        uint256 test_4_usdt_input = 1_000 * USDT_DECIMAL;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_4_usdt_input:", test_4_usdt_input);
        uint256 test_4_fcc = mockPool.calculateFccByUsdt_mock(test_4_usdt_input);
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_4_fcc:", test_4_fcc);
        uint256 test_4_div = (test_4_usdt_input * constant_decimal) / test_4_fcc;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_4_div:", test_4_div);
        assertTrue(test_4_div == 9, "test_4_div == 11111111");

        uint256 test_5_usdt_input = 999 * USDT_DECIMAL;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_5_usdt_input:", test_5_usdt_input);
        uint256 test_5_fcc = mockPool.calculateFccByUsdt_mock(test_5_usdt_input);
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_5_fcc:", test_5_fcc);
        uint256 test_5_div = (test_5_usdt_input * constant_decimal) / test_5_fcc;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_5_div:", test_5_div);
        assertTrue(test_5_div == 10, "test_5_div == 10");

        uint256 test_6_usdt_input = 1 * USDT_DECIMAL;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_6_usdt_input:", test_6_usdt_input);
        uint256 test_6_fcc = mockPool.calculateFccByUsdt_mock(test_6_usdt_input);
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_6_fcc:", test_6_fcc);
        uint256 test_6_div = (test_6_usdt_input * constant_decimal) / test_6_fcc;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_6_div:", test_6_div);
        assertTrue(test_6_div == 10, "test_6_div == 10");

        uint256 test_7_usdt_input = 0 * USDT_DECIMAL;
        try mockPool.calculateFccByUsdt_mock(test_7_usdt_input) returns (uint256 result) {
            assertTrue(false, "If the program runs to this line, it is abnormal");
            console.log("InvestorSalePoolTest calculateFccByUsdt_mock result:", result);
        } catch Error(string memory reason) {
            console.log("Error: ", reason);
            assertTrue(false, "If the program runs to this line, it is abnormal");
        } catch (bytes memory lowLevelData) {
            string memory hexString = toHexString(lowLevelData);
            console.log("Hex String:", hexString);
            assertTrue(true, "If the program runs to this line, it is normal");
        }
    }

    function test_calculateUsdtByFcc() public {
        // The denominator is expanded by a factor of 100
        uint256 constant_decimal = 1e2;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc constant_decimal:", constant_decimal);

        MockInvestorSalePool mockPool = new MockInvestorSalePool();

        console.log("InvestorSalePoolTest test_calculateUsdtByFcc usdtDecimal:", mockPool.getUsdtDecimal_mock());
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc fccDecimal:", mockPool.getFccDecimal_mock());

        uint256 FCC_DECIMAL = mockPool.getFccDecimal_mock();

        uint256 test_1_fcc_input = 5_000_000 * FCC_DECIMAL;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_1_fcc_input:", test_1_fcc_input);
        uint256 test_1_usdt = mockPool.calculateUsdtByFcc_mock(test_1_fcc_input);
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_1_usdt:", test_1_usdt);
        uint256 test_1_div = (test_1_usdt * constant_decimal) / test_1_fcc_input;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_1_div:", test_1_div);
        assertTrue(test_1_div == 6, "test_1_div == 6");

        uint256 test_2_fcc_input = 250_000 * FCC_DECIMAL;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_2_fcc_input:", test_2_fcc_input);
        uint256 test_2_usdt = mockPool.calculateUsdtByFcc_mock(test_2_fcc_input);
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_2_usdt:", test_2_usdt);
        uint256 test_2_div = (test_2_usdt * constant_decimal) / test_2_fcc_input;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_2_div:", test_2_div);
        assertTrue(test_2_div == 7, "test_2_div == 7");

        uint256 test_3_fcc_input = 100_000 * FCC_DECIMAL;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_3_fcc_input:", test_3_fcc_input);
        uint256 test_3_usdt = mockPool.calculateUsdtByFcc_mock(test_3_fcc_input);
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_3_usdt:", test_3_usdt);
        uint256 test_3_div = (test_3_usdt * constant_decimal) / test_3_fcc_input;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_3_div:", test_3_div);
        assertTrue(test_3_div == 8, "test_3_div == 8");

        uint256 test_4_fcc_input = 16_666 * FCC_DECIMAL;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_4_fcc_input:", test_4_fcc_input);
        uint256 test_4_usdt = mockPool.calculateUsdtByFcc_mock(test_4_fcc_input);
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_4_usdt:", test_4_usdt);
        uint256 test_4_div = (test_4_usdt * constant_decimal) / test_4_fcc_input;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_4_div:", test_4_div);
        assertTrue(test_4_div == 9, "test_4_div == 9");

        uint256 test_5_fcc_input = 16_665 * FCC_DECIMAL;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_5_fcc_input:", test_5_fcc_input);
        uint256 test_5_usdt = mockPool.calculateUsdtByFcc_mock(test_5_fcc_input);
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_5_usdt:", test_5_usdt);
        uint256 test_5_div = (test_5_usdt * constant_decimal) / test_5_fcc_input;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_5_div:", test_5_div);
        assertTrue(test_5_div == 10, "test_5_div == 10");

        uint256 test_6_fcc_input = 1 * FCC_DECIMAL;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_6_fcc_input:", test_6_fcc_input);
        uint256 test_6_usdt = mockPool.calculateUsdtByFcc_mock(test_6_fcc_input);
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_6_usdt:", test_6_usdt);
        uint256 test_6_div = (test_6_usdt * constant_decimal) / test_6_fcc_input;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_6_div:", test_6_div);
        assertTrue(test_6_div == 10, "test_6_div == 10");

        uint256 test_7_usdt_input = 0 * FCC_DECIMAL;
        try mockPool.calculateUsdtByFcc_mock(test_7_usdt_input) returns (uint256 result) {
            assertTrue(false, "If the program runs to this line, it is abnormal");
            console.log("InvestorSalePoolTest calculateUsdtByFcc_mock result:", result);
        } catch Error(string memory reason) {
            console.log("Error: ", reason);
            assertTrue(false, "If the program runs to this line, it is abnormal");
        } catch (bytes memory lowLevelData) {
            string memory hexString = toHexString(lowLevelData);
            console.log("Hex String:", hexString);
            assertTrue(true, "If the program runs to this line, it is normal");
        }
    }

    function toHexString(bytes memory data) internal pure returns (string memory) {
        bytes memory hexSymbols = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = '0';
        str[1] = 'x';

        for (uint i = 0; i < data.length; i++) {
            uint8 byteValue = uint8(data[i]);
            str[2 + i * 2] = hexSymbols[byteValue >> 4];
            str[3 + i * 2] = hexSymbols[byteValue & 0x0f];
        }

        return string(str);
    }
}
