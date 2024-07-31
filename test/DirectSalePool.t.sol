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
contract DirectSalePoolTest is Test {
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
    function testBuy() public {
        //DirectSalePool
        vm.startPrank(merchant);
        {
            usdt.approve(address(directSalePool), 10_000e6);
            console.log("approve==",usdt.allowance(merchant,address(directSalePool))/1e6);
            console.log("befor Buy merchant usdt balance ",usdt.balanceOf(address(merchant))/ 1e6); 
            console.log("befor Buy directSalePool fct balance ",fct.balanceOf(address(directSalePool))/ 1e6);
            console.log("befor Buy directSalePool usdt balance ",usdt.balanceOf(address(directSalePool))/ 1e6);
            console.log("befor Buy redemptionPool usdt balance ",usdt.balanceOf(address(redemptionPool))/ 1e6);            
            directSalePool.Buy(10_000e6);
            assertEq(1_000e6, usdt.balanceOf(address(redemptionPool)));
            assertEq(10_000e6, fct.balanceOf(address(merchant)));

            console.log("after Buy directSalePool fct balance ",fct.balanceOf(address(directSalePool))/ 1e6);
            console.log("after Buy directSalePool usdt balance ",usdt.balanceOf(address(directSalePool))/ 1e6);
            console.log("after Buy redemptionPool usdt balance ",usdt.balanceOf(address(redemptionPool))/ 1e6);
            console.log("after Buy merchant fct balance ",fct.balanceOf(address(merchant))/ 1e6);
            console.log("after Buy merchant usdt balance ",usdt.balanceOf(address(merchant))/ 1e6);
        }
        vm.stopPrank();
    }

    function testBuyWithUSDT() public {
        //DirectSalePool
        vm.startPrank(merchant);
        {
            usdt.approve(address(directSalePool), 10_000e6);
            console.log("approve==",usdt.allowance(merchant,address(directSalePool))/1e6);
            console.log("befor BuyWithUSDT merchant usdt balance ",usdt.balanceOf(address(merchant))/ 1e6); 
            console.log("befor BuyWithUSDT directSalePool fct balance ",fct.balanceOf(address(directSalePool))/ 1e6);
            console.log("befor BuyWithUSDT directSalePool usdt balance ",usdt.balanceOf(address(directSalePool))/ 1e6);
            console.log("befor BuyWithUSDT redemptionPool usdt balance ",usdt.balanceOf(address(redemptionPool))/ 1e6);            
            directSalePool.BuyWithUSDT(10_000e6);
            assertEq(10_000e6, usdt.balanceOf(address(redemptionPool)));
            console.log("after BuyWithUSDT directSalePool fct balance ",fct.balanceOf(address(directSalePool))/ 1e6);
            console.log("after BuyWithUSDT directSalePool usdt balance ",usdt.balanceOf(address(directSalePool))/ 1e6);
            console.log("after BuyWithUSDT redemptionPool usdt balance ",usdt.balanceOf(address(redemptionPool))/ 1e6);
            console.log("after BuyWithUSDT merchant fct balance ",fct.balanceOf(address(merchant))/ 1e6);
            console.log("after BuyWithUSDT merchant usdt balance ",usdt.balanceOf(address(merchant))/ 1e6);
        }
        vm.stopPrank();
    }
    

}