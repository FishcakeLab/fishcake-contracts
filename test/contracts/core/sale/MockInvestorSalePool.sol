// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
//import {InvestorSalePool} from "@contracts/core/sale/InvestorSalePool.sol";
import {InvestorSalePool} from "@contracts/core/sale/InvestorSalePool.sol";

contract MockInvestorSalePool is InvestorSalePool {
//    constructor() InvestorSalePool(address(1), address(2), address(3)) {
//        // Mock implementation or leave empty
//    }

    function getUsdtDecimal_mock() public pure returns (uint256) {
        return usdtDecimal;
    }

    function getFccDecimal_mock() public pure returns (uint256) {
        return fccDecimal;
    }

    function calculateFccByUsdt_mock(uint256 _amount) public pure returns (uint256) {
        return super.calculateFccByUsdt(_amount);
    }

    function calculateUsdtByFcc_mock(uint256 _amount) public pure returns (uint256) {
        return super.calculateUsdtByFcc(_amount);
    }
}
