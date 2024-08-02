// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {NFTManager} from "../src/contracts/core/NFTManager.sol";
import {UsdtToken} from "../src/contracts/core/UsdtToken.sol";
import {FishcakeCoin} from "../src/contracts/core/token/FishcakeCoin.sol";
import {RedemptionPool} from "../src/contracts/core/RedemptionPool.sol";
import {DirectSalePool} from "../src/contracts/core/sale/DirectSalePool.sol";
import {InvestorSalePool} from "../src/contracts/core/sale/InvestorSalePool.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
contract InvestorSalePoolTest is Test {
    using SafeERC20 for UsdtToken;
    using SafeERC20 for FishcakeCoin;
    
    address admin = makeAddr("admin");
    address merchant = makeAddr("merchant");
    address user = makeAddr("user");
    address merchantManger = makeAddr("merchantManger");
    address nFTManager = makeAddr("nFTManager");
    address Airdrop = makeAddr("Airdrop");
    address Foundation = makeAddr("Foundation");
    error AmountLessThanMinimum();
   


    FishcakeCoin public fct;
    UsdtToken public usdt;
    RedemptionPool public redemptionPool ;
    DirectSalePool public directSalePool;
    InvestorSalePool public investorSalePool;

    function setUp() public {
        //Deploying and minting the basic functions as an administrator.
        vm.startPrank(admin);
        {
        fct = new FishcakeCoin();
 
        usdt = new UsdtToken(admin);
        usdt.mint(admin, 1000000000e6);
        usdt.mint(merchant, 1000000000e6);
        usdt.mint(user, 1000000000e6);

        redemptionPool = new RedemptionPool(address(fct),address(usdt));
        directSalePool = new DirectSalePool(
            address(fct),
            address(redemptionPool),address(usdt)
        );
        investorSalePool = new InvestorSalePool(
            address(fct),
            address(redemptionPool),address(usdt)
        );
        investorSalePool.setValut(admin);   
        fct.setPoolAddress(
            address(merchantManger),
            address(directSalePool),
            address(investorSalePool),
            address(nFTManager),
            Airdrop,
            Foundation
        );
        fct.setRedemptionPool(address(redemptionPool));
        //mint coin
        fct.PoolAllocation(); 
        
        
        }
        vm.stopPrank();
    }
    function testInvestorSalePool() public {
        vm.startPrank(admin);
        {
            
            usdt.approve(address(investorSalePool), 10_000e6);
            InvestorSalePool.InvestorLevel level=investorSalePool.QueryLevelWithUSDT(10_000e6);
            uint256 fishcakeCoinAmount = investorSalePool.calculateFCC(level, 10_000e6);
            console.log("InvestorSalePool fishcakeCoinAmount ",fishcakeCoinAmount / 1e6);
            if (fishcakeCoinAmount > fct.balanceOf(address(investorSalePool))) {
            console.log("error");
            }
            console.log("approve==",usdt.allowance(admin,address(investorSalePool))/1e6);

            //usdt.safeTransferFrom(admin, address(investorSalePool), 10_000e6);
            
            //usdt.safeTransfer(address(redemptionPool), 10_000e6 / 2);
            //fct.safeTransfer(admin, fishcakeCoinAmount);
            investorSalePool.BuyWithUSDT(10_000e6);

           // console.log("InvestorSalePool level ",bba);
            //investorSalePool.BuyWithUSDT(10_000e6);

            
            console.log("investorSalePool fct balance ",fct.balanceOf(address(investorSalePool))/ 1e6);
        }
        
    }

    function testBuyWithUSDT() public {
        vm.startPrank(merchant);
        {
            
            usdt.approve(address(investorSalePool), 10_000e6);
            InvestorSalePool.InvestorLevel level=investorSalePool.QueryLevelWithUSDT(10_000e6);
            uint256 fishcakeCoinAmount = investorSalePool.calculateFCC(level, 10_000e6);
            console.log("InvestorSalePool fishcakeCoinAmount ",fishcakeCoinAmount / 1e6);
            if (fishcakeCoinAmount > fct.balanceOf(address(investorSalePool))) {
            console.log("error");
            }
            console.log("approve==",usdt.allowance(merchant,address(investorSalePool))/1e6);

            console.log("before BuyWithUSD investorSalePool usdt balance ",usdt.balanceOf(address(investorSalePool))/ 1e6);
            console.log("before BuyWithUSD redemptionPool usdt balance ",usdt.balanceOf(address(investorSalePool))/ 1e6);

            investorSalePool.BuyWithUSDT(10_000e6);
            console.log("after BuyWithUSD investorSalePool fct balance ",fct.balanceOf(address(investorSalePool))/ 1e6);
            console.log("after BuyWithUSD investorSalePool usdt balance ",usdt.balanceOf(address(investorSalePool))/ 1e6);
            console.log("after BuyWithUSD redemptionPool usdt balance ",usdt.balanceOf(address(investorSalePool))/ 1e6);

        }
        
    }

    function testBuy() public {
        vm.startPrank(merchant);
        {            
            usdt.approve(address(investorSalePool), 10_000e6);
            InvestorSalePool.InvestorLevel level=investorSalePool.QueryLevelWithFCC(16_666e6);
            uint256 USDTAmount = investorSalePool.calculateUSDT(level, 16_666e6);
            console.log("merchant should pay InvestorSalePool USDTAmount ",USDTAmount);
            if (16_666e6 > fct.balanceOf(address(investorSalePool))) {
            console.log("error");
            }
            console.log("approve==",usdt.allowance(merchant,address(investorSalePool))/1e6);

            console.log("before BuyWithUSD merchant usdt balance ",usdt.balanceOf(address(merchant))/ 1e6);
            console.log("before BuyWithUSD investorSalePool usdt balance ",usdt.balanceOf(address(investorSalePool))/ 1e6);
            console.log("before BuyWithUSD redemptionPool usdt balance ",usdt.balanceOf(address(redemptionPool))/ 1e6);

            //10_000 fcc ==>AmountLessThanMinimum,At least 16666 are required
            //vm.expectRevert(AmountLessThanMinimum.selector);
            investorSalePool.Buy(16_666e6);
            console.log("after BuyWithUSD investorSalePool fct balance ",fct.balanceOf(address(investorSalePool)));
            console.log("after BuyWithUSD merchant usdt balance ",usdt.balanceOf(address(merchant)));
            console.log("after BuyWithUSD investorSalePool usdt balance ",usdt.balanceOf(address(investorSalePool)));
            console.log("after BuyWithUSD redemptionPool usdt balance ",usdt.balanceOf(address(redemptionPool)));



            console.log("after BuyWithUSDT merchant fct balance ",fct.balanceOf(address(merchant)));


        }        
    }

    function testwithdrawUSDT() public {
        vm.startPrank(merchant);
        {
            
            usdt.approve(address(investorSalePool), 10_000e6);
            InvestorSalePool.InvestorLevel level=investorSalePool.QueryLevelWithUSDT(10_000e6);
            uint256 fishcakeCoinAmount = investorSalePool.calculateFCC(level, 10_000e6);
            console.log("InvestorSalePool fishcakeCoinAmount ",fishcakeCoinAmount / 1e6);
            if (fishcakeCoinAmount > fct.balanceOf(address(investorSalePool))) {
            console.log("error");
            }
            console.log("approve==",usdt.allowance(merchant,address(investorSalePool))/1e6);

            console.log("before BuyWithUSD investorSalePool usdt balance ",usdt.balanceOf(address(investorSalePool))/ 1e6);
            console.log("before BuyWithUSD redemptionPool usdt balance ",usdt.balanceOf(address(redemptionPool))/ 1e6);

            investorSalePool.BuyWithUSDT(10_000e6);
            console.log("after BuyWithUSD investorSalePool fct balance ",fct.balanceOf(address(investorSalePool))/ 1e6);
            console.log("after BuyWithUSD investorSalePool usdt balance ",usdt.balanceOf(address(investorSalePool))/ 1e6);
            console.log("after BuyWithUSD redemptionPool usdt balance ",usdt.balanceOf(address(redemptionPool))/ 1e6);



            console.log("after BuyWithUSDT merchant fct balance ",fct.balanceOf(address(merchant))/ 1e6);

        }
        
        vm.startPrank(admin);{
            console.log("before withdrawUSDT admin usdt balance ",usdt.balanceOf(address(admin))/ 1e6);
            investorSalePool.withdrawUSDT(5_000e6);
            console.log("after withdrawUSDT admin usdt balance ",usdt.balanceOf(address(admin))/ 1e6);
        }
    }
}