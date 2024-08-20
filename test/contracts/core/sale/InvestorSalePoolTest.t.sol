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
        // 调用通过代理合约进行
        InvestorSalePool tempInvestorSalePool = InvestorSalePool(address(proxyInvestorSalePool));

        uint256 before_tempInvestorSalePool_fcc = tempFishCakeCoin.FccBalance(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_buyFccAmount before_tempInvestorSalePool_fcc:", before_tempInvestorSalePool_fcc);
        uint256 before_tempInvestorSalePool_usdt = usdtToken.balanceOf(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_buyFccAmount before_tempInvestorSalePool_usdt:", before_tempInvestorSalePool_usdt);

        uint256 before_redemptionPool_fcc = tempFishCakeCoin.FccBalance(address(redemptionPool));
        console.log("InvestorSalePoolTest test_buyFccAmount before_redemptionPool_fcc:", before_redemptionPool_fcc);
        uint256 before_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("InvestorSalePoolTest test_buyFccAmount before_redemptionPool_usdt:", before_redemptionPool_fcc);

        uint256 before_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("InvestorSalePoolTest test_buyFccAmount before_deployerAddress_fcc:", before_deployerAddress_fcc);
        uint256 before_deployerAddress_usdt = usdtToken.balanceOf(deployerAddress);
        console.log("InvestorSalePoolTest test_buyFccAmount before_deployerAddress_usdt:", before_deployerAddress_usdt);

        uint256 fcc_amount = 16_666 * tempInvestorSalePool.fccDecimal();
        vm.startPrank(deployerAddress);
        usdtToken.approve(address(tempInvestorSalePool), fcc_amount);
        tempInvestorSalePool.buyFccAmount(fcc_amount);
        vm.stopPrank();

        // 调用通过代理合约进行
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
        // 调用通过代理合约进行
        InvestorSalePool tempInvestorSalePool = InvestorSalePool(address(proxyInvestorSalePool));

        uint256 before_tempInvestorSalePool_fcc = tempFishCakeCoin.FccBalance(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount before_tempInvestorSalePool_fcc:", before_tempInvestorSalePool_fcc);
        uint256 before_tempInvestorSalePool_usdt = usdtToken.balanceOf(address(tempInvestorSalePool));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount before_tempInvestorSalePool_usdt:", before_tempInvestorSalePool_usdt);
        uint256 before_redemptionPool_fcc = tempFishCakeCoin.FccBalance(address(redemptionPool));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount before_redemptionPool_fcc:", before_redemptionPool_fcc);
        uint256 before_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount before_redemptionPool_usdt:", before_redemptionPool_fcc);
        uint256 before_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount before_deployerAddress_fcc:", before_deployerAddress_fcc);
        uint256 before_deployerAddress_usdt = usdtToken.balanceOf(deployerAddress);
        console.log("InvestorSalePoolTest test_buyFccByUsdtAmount before_deployerAddress_usdt:", before_deployerAddress_usdt);

        uint256 usdt_amount = 1_000 * tempInvestorSalePool.usdtDecimal();

        vm.startPrank(deployerAddress);
        usdtToken.approve(address(tempInvestorSalePool), usdt_amount);
        tempInvestorSalePool.buyFccByUsdtAmount(usdt_amount);
        vm.stopPrank();

        // 调用通过代理合约进行
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
        // 调用通过代理合约进行
        IInvestorSalePool tempInvestorSalePool = IInvestorSalePool(address(proxyInvestorSalePool));

        vm.startPrank(deployerAddress);
        tempInvestorSalePool.setValutAddress(deployerAddress);
        vm.stopPrank();

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
        // 调用通过代理合约进行
        MockInvestorSalePool mockPool = new MockInvestorSalePool();

        console.log("InvestorSalePoolTest test_calculateFccByUsdt usdtDecimal:", mockPool.getUsdtDecimal_mock());
        console.log("InvestorSalePoolTest test_calculateFccByUsdt fccDecimal:", mockPool.getFccDecimal_mock());

        uint256 tempUsdt = mockPool.getUsdtDecimal_mock();

        uint256 test_1_usdt_input = 100_000 * tempUsdt;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_1_usdt_input:", test_1_usdt_input);
        uint256 test_1_fcc = mockPool.calculateFccByUsdt_mock(test_1_usdt_input);
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_1_fcc:", test_1_fcc);
        uint256 test_1_div = test_1_fcc * 100 / test_1_usdt_input;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_1_div:", test_1_div);
        assertTrue(test_1_div == 5000, "test_1_div == 5000");

        uint256 test_2_usdt_input = 10_000 * tempUsdt;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_2_usdt_input:", test_2_usdt_input);
        uint256 test_2_fcc = mockPool.calculateFccByUsdt_mock(test_2_usdt_input);
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_2_fcc:", test_2_fcc);
        uint256 test_2_div = test_2_fcc * 100 / test_2_usdt_input;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_2_div:", test_2_div);
        assertTrue(test_2_div == 2500, "test_2_div == 2500");

        uint256 test_3_usdt_input = 5_000 * tempUsdt;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_3_usdt_input:", test_3_usdt_input);
        uint256 test_3_fcc = mockPool.calculateFccByUsdt_mock(test_3_usdt_input);
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_3_fcc:", test_3_fcc);
        uint256 test_3_div = test_3_fcc * 100 / test_3_usdt_input;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_3_div:", test_3_div);
        assertTrue(test_3_div == 2000, "test_3_div == 2000");

        uint256 test_4_usdt_input = 1_000 * tempUsdt;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_4_usdt_input:", test_4_usdt_input);
        uint256 test_4_fcc = mockPool.calculateFccByUsdt_mock(test_4_usdt_input);
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_4_fcc:", test_4_fcc);
        uint256 test_4_div = test_4_fcc * 100 / test_4_usdt_input;
        console.log("InvestorSalePoolTest test_calculateFccByUsdt test_4_div:", test_4_div);
        assertTrue(test_4_div == 1666, "test_4_div == 1666");

        uint256 test_5_usdt_input = 999 * tempUsdt;
        try mockPool.calculateFccByUsdt_mock(test_5_usdt_input) returns (uint256 result) {
            // 打印计算结果
            assertTrue(false, "If the program runs to this line, it is abnormal");
            console.log("InvestorSalePoolTest test_calculateFccByUsdt test_5_fcc:", result);
        } catch Error(string memory reason) {
            // 捕获并打印标准错误
            console.log("Error: ", reason);
            assertTrue(false, "If the program runs to this line, it is abnormal");
        } catch (bytes memory lowLevelData) {
            // 捕获并打印底层错误
            string memory hexString = toHexString(lowLevelData);
            console.log("Hex String:", hexString);
            assertTrue(true, "If the program runs to this line, it is normal");
        }
    }

    function test_calculateUsdtByFcc() public {
        MockInvestorSalePool mockPool = new MockInvestorSalePool();

        console.log("InvestorSalePoolTest test_calculateUsdtByFcc usdtDecimal:", mockPool.getUsdtDecimal_mock());
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc fccDecimal:", mockPool.getFccDecimal_mock());

        uint256 tempFcc = mockPool.getFccDecimal_mock();

        uint256 test_1_fcc_input = 5_000_000 * tempFcc;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc input fcc 1 :", test_1_fcc_input);
        uint256 test_1_usdt = mockPool.calculateUsdtByFcc_mock(test_1_fcc_input);
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_1_usdt:", test_1_usdt);
        uint256 test_1_div = test_1_usdt * 100 / test_1_fcc_input;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_1_div:", test_1_div);
        assertTrue(test_1_div == 2, "test_1_div == 2");

        uint256 test_2_input = 250_000 * tempFcc;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc input 2 :", test_2_input);
        uint256 test_2 = mockPool.calculateUsdtByFcc_mock(test_2_input);
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_2:", test_2);
        uint256 test_2_div = test_2 * 100 / test_2_input;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_2_div:", test_2_div);
        assertTrue(test_2_div == 4, "test_2_div == 4");

        uint256 test_3_input = 100_000 * tempFcc;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc input 3 :", test_3_input);
        uint256 test_3 = mockPool.calculateUsdtByFcc_mock(test_3_input);
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_3:", test_3);
        uint256 test_3_div = test_3 * 100 / test_3_input;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_3_div:", test_3_div);
        assertTrue(test_3_div == 5, "test_3_div == 5");

        uint256 test_4_input = 16_666 * tempFcc;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc input 4 :", test_4_input);
        uint256 test_4 = mockPool.calculateUsdtByFcc_mock(test_4_input);
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_4:", test_4);
        uint256 test_4_div = test_4 * 100 / test_4_input;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_4_div:", test_4_div);
        assertTrue(test_4_div == 6, "test_4_div == 6");

        uint256 test_5_input = 16_665 * tempFcc;
        console.log("InvestorSalePoolTest test_calculateUsdtByFcc input 5 :", test_5_input);
        try mockPool.calculateUsdtByFcc_mock(test_5_input) returns (uint256 result) {
            // 打印计算结果
            console.log("InvestorSalePoolTest test_calculateUsdtByFcc test_5:", result);
        } catch Error(string memory reason) {
            // 捕获并打印标准错误
            console.log("InvestorSalePoolTest test_calculateUsdtByFcc Error: ", reason);
        } catch (bytes memory lowLevelData) {
//            console.log("InvestorSalePoolTest test_calculateUsdtByFcc Low level error: ", string(lowLevelData));
            string memory hexString = toHexString(lowLevelData);
            console.log("Hex String:", hexString);
        }
    }

    function toHexString(bytes memory data) internal pure returns (string memory) {
        // 用于十六进制转换的字符
        bytes memory hexSymbols = "0123456789abcdef";

        // 创建用于存储结果的字符串
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
