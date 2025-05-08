// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin-foundry-upgrades/Upgrades.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

import {FishCakeCoin} from "@contracts/core/token/FishCakeCoin.sol";
import {FishCakeCoinStorage} from "@contracts/core/token/FishCakeCoinStorage.sol";
import {RedemptionPool} from "@contracts/core/RedemptionPool.sol";
import {DirectSalePool} from "@contracts/core/sale/DirectSalePool.sol";
import {InvestorSalePool} from "@contracts/core/sale/InvestorSalePool.sol";
import {NftManagerV4 as NftManager} from "@contracts/core/token/NftManagerV4.sol";
import {FishcakeEventManagerV1 as FishcakeEventManager} from "@contracts/core/FishcakeEventManagerV1.sol";
import {UsdtERC20TestHelper} from "../UsdtERC20TestHelper.sol";

contract FishcakeEventManagerV1Test is Test {
    FishCakeCoin public fishCakeCoin;
    RedemptionPool public redemptionPool;
    UsdtERC20TestHelper public usdtToken;
    DirectSalePool public directSalePool;
    InvestorSalePool public investorSalePool;
    NftManager public nftManager;
    FishcakeEventManager public fishcakeEventManager;

    Account owner = makeAccount("owner");
    address internal proxyFishCakeCoin; // FishCakeCoin 的代理地址
    address internal proxyFishcakeEventManager; // FishcakeEventManager 的代理地址
    address internal proxyDirectSalePool; // DirectSalePool 的代理地址
    address internal proxyInvestorSalePool; // InvestorSalePool 的代理地址
    address internal proxyNftManager; // NftManager 的代理地址

    address internal usdtTokenAddress; // USDT 代币地址

    function setUp() public {
        // 1. 部署 FishCakeCoin 合约
        fishCakeCoin = new FishCakeCoin();
        proxyFishCakeCoin = Upgrades.deployTransparentProxy(
            "FishCakeCoin.sol:FishCakeCoin",
            owner.addr,
            abi.encodeWithSelector(FishCakeCoin.initialize.selector, owner.addr, address(0))
        );

        // 2. 部署 UsdtERC20TestHelper 合约
        usdtToken = new UsdtERC20TestHelper("USDTToken", "USDT", 1000 * 1e18, owner.addr);
        console.log("deploy usdtToken:", address(usdtToken));
        usdtTokenAddress = address(usdtToken);

        // 3. 部署 RedemptionPool 合约
        redemptionPool = new RedemptionPool(address(proxyFishCakeCoin), usdtTokenAddress);
        console.log("deploy redemptionPool:", address(redemptionPool));

        // 4. 部署 DirectSalePool 合约
        directSalePool = new DirectSalePool();
        proxyDirectSalePool = Upgrades.deployTransparentProxy(
            "DirectSalePool.sol:DirectSalePool",
            owner.addr,
            abi.encodeWithSelector(
                DirectSalePool.initialize.selector, owner.addr, proxyFishCakeCoin, redemptionPool, usdtTokenAddress
            )
        );
        console.log("deploy proxyDirectSalePool:", address(proxyDirectSalePool));

        // 4. 部署 InvestorSalePool 合约
        investorSalePool = new InvestorSalePool();
        proxyInvestorSalePool = Upgrades.deployTransparentProxy(
            "InvestorSalePool.sol:InvestorSalePool",
            owner.addr,
            abi.encodeWithSelector(
                InvestorSalePool.initialize.selector, owner.addr, proxyFishCakeCoin, redemptionPool, usdtTokenAddress
            )
        );
        console.log("deploy proxyInvestorSalePool:", address(proxyInvestorSalePool));

        // 5. 部署 NftManager 合约
        nftManager = new NftManager();
        proxyNftManager = Upgrades.deployTransparentProxy(
            "NftManagerV4.sol:NftManagerV4",
            owner.addr,
            abi.encodeWithSelector(
                NftManager.initialize.selector, owner.addr, proxyFishCakeCoin, usdtTokenAddress, redemptionPool
            )
        );
        console.log("deploy proxyNftManager:", address(proxyNftManager));

        // 6. 部署 FishcakeEventManager 合约
        fishcakeEventManager = new FishcakeEventManager();
        proxyFishcakeEventManager = Upgrades.deployTransparentProxy(
            "FishcakeEventManagerV1.sol:FishcakeEventManagerV1",
            owner.addr,
            abi.encodeWithSelector(
                FishcakeEventManager.initialize.selector,
                owner.addr,
                proxyFishCakeCoin,
                usdtTokenAddress,
                proxyNftManager
            )
        );
        console.log("deploy proxyFishcakeEventManager:", address(proxyFishcakeEventManager));

        // setUp
        vm.startPrank(owner.addr);
        FishCakeCoin(address(proxyFishCakeCoin)).setRedemptionPool(address(redemptionPool));
        InvestorSalePool(address(proxyInvestorSalePool)).setVaultAddress(owner.addr);

        FishCakeCoinStorage.fishCakePool memory fishCakePool = FishCakeCoinStorage.fishCakePool({
            miningPool: address(proxyFishcakeEventManager),
            directSalePool: address(proxyDirectSalePool),
            investorSalePool: address(proxyInvestorSalePool),
            nftSalesRewardsPool: address(proxyNftManager),
            ecosystemPool: owner.addr,
            foundationPool: owner.addr,
            redemptionPool: address(redemptionPool)
        });
        FishCakeCoin(address(proxyFishCakeCoin)).setPoolAddress(fishCakePool);

        FishCakeCoin(address(proxyFishCakeCoin)).poolAllocate();
        vm.stopPrank();
    }

    function test_setPoolAddress() public {
        vm.startPrank(owner.addr);
        (
            address miningPool,
            address directSalePoolAddress,
            address investorSalePoolAddress,
            address nftSalesRewardsPool,
            address ecosystemPool,
            address foundationPool,
            address redemptionPoolAddress
        ) = FishCakeCoin(address(proxyFishCakeCoin)).fcPool();
        console.log("deploy fishCakePool miningPool:", miningPool);
        console.log("deploy fishCakePool directSalePool:", directSalePoolAddress);
        console.log("deploy fishCakePool investorSalePool:", investorSalePoolAddress);
        console.log("deploy fishCakePool nftSalesRewardsPool:", nftSalesRewardsPool);
        console.log("deploy fishCakePool ecosystemPool:", ecosystemPool);
        console.log("deploy fishCakePool foundationPool:", foundationPool);
        console.log("deploy fishCakePool redemptionPool:", redemptionPoolAddress);
        assertEq(miningPool, proxyFishcakeEventManager); // 检查 miningPool 是否设置正确
        assertEq(directSalePoolAddress, proxyDirectSalePool); // 检查 directSalePool 是否设置正确
        assertEq(investorSalePoolAddress, proxyInvestorSalePool); // 检查 investorSalePool 是否设置正确
        assertEq(nftSalesRewardsPool, proxyNftManager); // 检查 nftSalesRewardsPool 是否设置正确
        vm.stopPrank();
    }

    function test_fishCakeCoin_balanceOf() public view {
        uint256 balance = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        console.log("owner.addr balance:", balance);
        assertEq(balance, 200_000_000_000_000); // 检查 owner.addr 的余额是否为 0
    }

    function testActivityAdd() public {
        // 准备活动参数
        string memory businessName = "Test Business";
        string memory content = "Test Content";
        string memory location = "0,0";
        uint256 deadline = block.timestamp + 20 days;
        uint256 totalAmount = 1000 * 10 ** 6;
        uint8 dropType = 1;
        uint256 dropNumber = 10;
        uint256 minDrop = 0;
        uint256 maxDrop = 100 * 10 ** 6; // 1 亿

        // 授权代币
        vm.startPrank(owner.addr);
        // Step 2: 授权给代理合约地址
        FishCakeCoin(proxyFishCakeCoin).approve(proxyFishcakeEventManager, totalAmount);
        // Step 3: 验证授权
        uint256 allowance = FishCakeCoin(proxyFishCakeCoin).allowance(owner.addr, proxyFishcakeEventManager);
        assertEq(allowance, totalAmount);

        // 测试添加活动
        (bool success, uint256 activityId) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            businessName,
            content,
            location,
            deadline,
            totalAmount,
            dropType,
            dropNumber,
            minDrop,
            maxDrop,
            proxyFishCakeCoin
        );

        assertTrue(success);
        assertEq(activityId, 1);
        vm.stopPrank();
    }

    // 测试空投功能
    function testDrop() public {
        uint256 totalAmount = 1000 * 10 ** 6;

        // 先创建一个活动
        vm.startPrank(owner.addr);
        FishCakeCoin(proxyFishCakeCoin).approve(proxyFishcakeEventManager, totalAmount);

        (bool success,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Test Business",
            "Test Content",
            "0,0",
            block.timestamp + 20 days,
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );
        assertTrue(success);

        // 测试空投
        address user = address(0x123);
        bool dropSuccess = FishcakeEventManager(proxyFishcakeEventManager).drop(1, user, 100 * 10 ** 6);
        assertTrue(dropSuccess);

        // 验证用户余额
        assertEq(FishCakeCoin(proxyFishCakeCoin).balanceOf(user), 100 * 10 ** 6);

        // 验证不能重复空投给同一用户
        vm.expectRevert("FishcakeEventManager drop: User Has Dropped.");
        FishcakeEventManager(proxyFishcakeEventManager).drop(1, user, 100 * 10 ** 6);

        vm.stopPrank();
    }

    // 测试活动结束功能
    function testActivityFinish() public {
        uint256 totalAmount = 1000 * 10 ** 6;

        // 先创建活动
        vm.startPrank(owner.addr);
        FishCakeCoin(proxyFishCakeCoin).approve(proxyFishcakeEventManager, totalAmount);

        (bool success,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Test Business",
            "Test Content",
            "0,0",
            block.timestamp + 20 days,
            1000 * 10 ** 6,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );
        assertTrue(success);

        // 执行一些空投
        address user = address(0x123);
        FishcakeEventManager(proxyFishcakeEventManager).drop(1, user, 100 * 10 ** 6);

        // 记录结束前的余额
        uint256 balanceBefore = FishCakeCoin(address(proxyFishCakeCoin)).balanceOf(owner.addr);

        // 结束活动
        bool finishSuccess = FishcakeEventManager(proxyFishcakeEventManager).activityFinish(1);
        assertTrue(finishSuccess);

        // 验证未使用的代币是否返还
        uint256 balanceAfter = FishCakeCoin(address(proxyFishCakeCoin)).balanceOf(owner.addr);
        assertEq(balanceAfter - balanceBefore, 900 * 10 ** 6); // 1000 - 100 = 900

        // 验证活动状态
        vm.expectRevert("FishcakeEventManager activityFinish: Activity Status Error.");
        FishcakeEventManager(proxyFishcakeEventManager).activityFinish(1);

        vm.stopPrank();
    }

    function testActivityDeadline() public {
        uint256 totalAmount = 1000 * 10 ** 6;
        vm.startPrank(owner.addr);
        FishCakeCoin(proxyFishCakeCoin).approve(proxyFishcakeEventManager, totalAmount);

        // 测试创建一个即将过期的活动
        uint256 shortDeadline = block.timestamp + 1 hours;
        (bool success,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Test Business",
            "Test Content",
            "0,0",
            shortDeadline,
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );
        assertTrue(success);

        // 时间快进到接近截止时间
        vm.warp(shortDeadline - 1);

        // 此时仍然可以空投
        address user = address(0x123);
        bool dropSuccess = FishcakeEventManager(proxyFishcakeEventManager).drop(1, user, 100 * 10 ** 6);
        assertTrue(dropSuccess);

        // 时间快进到过期
        vm.warp(shortDeadline + 1);
        // 验证过期后不能空投
        address user2 = address(0x456);
        vm.expectRevert("FishcakeEventManager drop: Activity Has Expired.");
        FishcakeEventManager(proxyFishcakeEventManager).drop(1, user2, 100 * 10 ** 6);

        vm.stopPrank();
    }

    function testInvalidDeadline() public {
        uint256 totalAmount = 1000 * 10 ** 6;
        vm.startPrank(owner.addr);
        FishCakeCoin(proxyFishCakeCoin).approve(proxyFishcakeEventManager, totalAmount);

        // 测试过去的时间
        vm.expectRevert("FishcakeEventManager activityAdd: Activity DeadLine Error.");
        FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Test Business",
            "Test Content",
            "0,0",
            0, // 过去的时间
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );

        // 测试太远的未来时间
        vm.expectRevert("FishcakeEventManager activityAdd: Activity DeadLine Error.");
        FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Test Business",
            "Test Content",
            "0,0",
            block.timestamp + 30 days, // 太远的未来
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );

        vm.stopPrank();
    }

    function testMiningTimeInterval() public {
        uint256 totalAmount = 1000 * 10 ** 6;
        vm.startPrank(owner.addr);
        FishCakeCoin(proxyFishCakeCoin).approve(proxyFishcakeEventManager, totalAmount * 2);

        // 创建第一个活动
        (bool success1,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Activity 1",
            "Test Content",
            "0,0",
            block.timestamp + 20 days,
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );
        assertTrue(success1);

        // 执行空投并结束第一个活动
        address user = address(0x123);
        FishcakeEventManager(proxyFishcakeEventManager).drop(1, user, 100 * 10 ** 6);
        bool finishSuccess1 = FishcakeEventManager(proxyFishcakeEventManager).activityFinish(1);
        assertTrue(finishSuccess1);

        // 记录第一次挖矿后的余额
        uint256 balanceAfterFirstMining = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        console.log("balanceAfterFirstMining", balanceAfterFirstMining);
        assertEq(balanceAfterFirstMining, 199_999_900_000_000, "balanceAfterFirstMining should be 199_999_900_000000");

        // 立即创建并结束第二个活动
        (bool success2,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Activity 2",
            "Test Content",
            "0,0",
            block.timestamp + 20 days,
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );
        assertTrue(success2);

        FishcakeEventManager(proxyFishcakeEventManager).drop(2, user, 100 * 10 ** 6);

        // 验证24小时内第二次挖矿不会获得奖励
        bool finishSuccess2 = FishcakeEventManager(proxyFishcakeEventManager).activityFinish(2);
        assertTrue(finishSuccess2);

        uint256 balanceAfterSecondMining = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        assertEq(balanceAfterSecondMining, 199_999_800_000_000, "balanceAfterSecondMining should be 199_999_800_000000"); // 只返还未使用的代币，没有挖矿奖励
        assertEq(
            balanceAfterFirstMining - balanceAfterSecondMining,
            100 * 10 ** 6,
            "Should not get mining reward within 24 hours"
        ); // 只返还未使用的代币，没有挖矿奖励

        // 时间快进25小时
        vm.warp(block.timestamp + 25 hours);

        // 创建并结束第三个活动，应该可以再次获得挖矿奖励
        FishCakeCoin(proxyFishCakeCoin).approve(proxyFishcakeEventManager, totalAmount);
        (bool success3,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Activity 3",
            "Test Content",
            "0,0",
            block.timestamp + 20 days,
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );
        assertTrue(success3);

        FishcakeEventManager(proxyFishcakeEventManager).drop(3, user, 100 * 10 ** 6);
        bool finishSuccess3 = FishcakeEventManager(proxyFishcakeEventManager).activityFinish(3);
        assertTrue(finishSuccess3);

        uint256 balanceAfterThirdMining = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        assertEq(balanceAfterThirdMining, 199_999_700_000_000, "balanceAfterThirdMining should be 199_999_700_000000");
        assertEq(balanceAfterSecondMining - balanceAfterThirdMining, 100 * 10 ** 6);

        vm.stopPrank();
    }

    // testActivityFinishByNonOwner: 测试非所有者无法结束活动 验证权限控制
    function testActivityFinishByNonOwner() public {
        uint256 totalAmount = 1000 * 10 ** 6;
        vm.startPrank(owner.addr);

        // 创建活动
        FishCakeCoin(proxyFishCakeCoin).approve(proxyFishcakeEventManager, totalAmount);
        (bool success,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Test Business",
            "Test Content",
            "0,0",
            block.timestamp + 20 days,
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );
        assertTrue(success);
        vm.stopPrank();

        // 非所有者尝试结束活动
        address nonOwner = address(0x999);
        vm.startPrank(nonOwner);
        vm.expectRevert("FishcakeEventManager activityFinish: Not The Owner.");
        FishcakeEventManager(proxyFishcakeEventManager).activityFinish(1);
        vm.stopPrank();
    }

    /**
     * testActivityFinishAfterDeadline: 测试在截止时间后结束活动
     *     验证可以在截止时间后结束活动
     *     验证代币返还功能
     */
    function testActivityFinishAfterDeadline() public {
        uint256 totalAmount = 1000 * 10 ** 6;
        vm.startPrank(owner.addr);

        // 创建活动
        FishCakeCoin(proxyFishCakeCoin).approve(proxyFishcakeEventManager, totalAmount);
        (bool success,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Test Business",
            "Test Content",
            "0,0",
            block.timestamp + 1 days,
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );
        assertTrue(success);

        // 执行一些空投
        address user = address(0x123);
        FishcakeEventManager(proxyFishcakeEventManager).drop(1, user, 100 * 10 ** 6);

        // 时间快进到截止时间后
        vm.warp(block.timestamp + 2 days);

        // 结束活动应该仍然成功
        bool finishSuccess = FishcakeEventManager(proxyFishcakeEventManager).activityFinish(1);
        assertTrue(finishSuccess);

        vm.stopPrank();
    }

    // testActivityFinishWithoutMining: 测试24小时内第二次结束活动不会获得挖矿奖励
    // 验证只返还未使用代币
    // 验证没有挖矿奖励
    function testActivityFinishWithoutMining() public {
        uint256 totalAmount = 1000 * 10 ** 6;
        vm.startPrank(owner.addr);

        // 1. 先完成一次挖矿活动
        FishCakeCoin(proxyFishCakeCoin).approve(proxyFishcakeEventManager, totalAmount * 2);

        // 第一个活动
        (bool success1,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Activity 1",
            "Test Content",
            "0,0",
            block.timestamp + 20 days,
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );
        assertTrue(success1);

        // 执行空投并结束第一个活动
        address user = address(0x123);
        FishcakeEventManager(proxyFishcakeEventManager).drop(1, user, 100 * 10 ** 6);
        bool finishSuccess1 = FishcakeEventManager(proxyFishcakeEventManager).activityFinish(1);
        assertTrue(finishSuccess1);

        // 2. 立即创建第二个活动（24小时内）
        (bool success2,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Activity 2",
            "Test Content",
            "0,0",
            block.timestamp + 20 days,
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );
        assertTrue(success2);

        // 记录结束前的余额
        uint256 balanceBefore = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);

        // 执行空投并结束第二个活动
        FishcakeEventManager(proxyFishcakeEventManager).drop(2, user, 100 * 10 ** 6);
        bool finishSuccess2 = FishcakeEventManager(proxyFishcakeEventManager).activityFinish(2);
        assertTrue(finishSuccess2);

        // 验证只返还未使用代币，没有挖矿奖励
        uint256 balanceAfter = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        assertEq(balanceAfter - balanceBefore, 900 * 10 ** 6, "Should only return unused tokens without mining reward");

        vm.stopPrank();
    }

    /*
    testActivityFinishWithMining: 测试正常的活动结束并获得挖矿奖励
    验证代币返还
    验证挖矿奖励
    验证合约余额变化
    */
    function testActivityFinishWithMining() public {
        uint256 totalAmount = 1000 * 10 ** 6;
        vm.startPrank(owner.addr);

        // 1. 创建活动
        FishCakeCoin(proxyFishCakeCoin).approve(proxyFishcakeEventManager, totalAmount);
        (bool success,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Test Business",
            "Test Content",
            "0,0",
            block.timestamp + 20 days,
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );
        assertTrue(success);

        // 2. 执行多次空投以增加挖矿收益
        address[] memory users = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            users[i] = address(uint160(i + 1));
            FishcakeEventManager(proxyFishcakeEventManager).drop(1, users[i], 100 * 10 ** 6);
        }

        // 3. 记录结束前的各种余额
        uint256 balanceBefore = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        uint256 contractBalanceBefore = FishCakeCoin(proxyFishCakeCoin).balanceOf(proxyFishcakeEventManager);

        // 4. 结束活动
        bool finishSuccess = FishcakeEventManager(proxyFishcakeEventManager).activityFinish(1);
        assertTrue(finishSuccess);

        // 5. 验证余额变化
        uint256 balanceAfter = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        uint256 contractBalanceAfter = FishCakeCoin(proxyFishCakeCoin).balanceOf(proxyFishcakeEventManager);

        // 验证返还金额（未使用的代币）
        uint256 returnedAmount = 500 * 10 ** 6; // 1000 - (5 * 100) = 500
        assertEq(balanceAfter - balanceBefore >= returnedAmount, true, "Should return unused tokens");

        // 验证合约余额变化
        assertEq(
            contractBalanceBefore - contractBalanceAfter,
            returnedAmount + (balanceAfter - balanceBefore - returnedAmount), // 返还金额 + 挖矿奖励
            "Contract balance change should match returned + mined amount"
        );

        vm.stopPrank();
    }

    function testIfRewardLogic() public {
        vm.startPrank(owner.addr);

        // 准备 USDT 代币并授权
        uint256 usdtAmount = 80 * 10 ** 6; // 假设 merchantValue 是 80 USDT（6位小数）
        deal(usdtTokenAddress, owner.addr, usdtAmount); // 用 Foundry 的 deal 作弊码给 owner USDT
        UsdtERC20TestHelper(usdtTokenAddress).approve(proxyNftManager, usdtAmount);

        // 调用 createNFT 设置商户 NFT 截止时间
        (bool success,) = NftManager(payable(proxyNftManager)).createNFT(
            "Test Business",
            "Test Description",
            "ipfs://test-image",
            "Test Address",
            "https://test.com",
            "@test_social",
            1 // 商户类型
        );
        assertTrue(success);

        // 验证截止时间已设置
        uint256 deadline = NftManager(payable(proxyNftManager)).getMerchantNTFDeadline(owner.addr);
        assertTrue(deadline > block.timestamp); // 截止时间应大于当前时间

        uint256 balanceBeforeFishCakeCoin = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        uint256 contractBalanceBeforeFEM = FishCakeCoin(proxyFishCakeCoin).balanceOf(proxyFishcakeEventManager);
        assertEq(
            balanceBeforeFishCakeCoin, 200_001_000_000_000, "owner should have 200_001_000 FishCakeCoin before mining"
        );

        assertEq(
            contractBalanceBeforeFEM, 300_000_000_000_000, "contract should have 300_000_000 FishCakeCoin before mining"
        );

        // 1. 测试首次挖矿（NTFLastMineTime 为 0）
        uint256 totalAmount = 1000 * 10 ** 6;
        FishCakeCoin(proxyFishCakeCoin).approve(proxyFishcakeEventManager, totalAmount * 3);

        // 前提条件：
        // owner 必须有足够的 FCC 或 USDT 余额（取决于 _tokenContractAddr）。

        // owner 必须授权 FishcakeEventManager 使用这些代币（通过 approve）。

        // 创建并完成第一个活动
        (bool success1,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Activity 1",
            "Test Content",
            "0,0",
            block.timestamp + 20 days,
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            proxyFishCakeCoin
        );
        assertTrue(success1);

        address user = address(0x123);
        FishcakeEventManager(proxyFishcakeEventManager).drop(1, user, 100 * 10 ** 6);

        uint256 balanceBefore = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        assertEq(balanceBefore, 200_000_000_000_000, "owner should have 200_000_000 FishCakeCoin before activityFinish");
        bool finishSuccess1 = FishcakeEventManager(proxyFishcakeEventManager).activityFinish(1);
        assertTrue(finishSuccess1);
        uint256 balanceAfter = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        assertEq(balanceAfter, 200_000_910_000_000, "owner should have 200_000_910 FishCakeCoin after activityFinish");

        // 首次应该能获得挖矿奖励
        assertTrue(balanceAfter > balanceBefore + 900 * 10 ** 6, "Should get mining reward for first time");

        // 2. 推进 23 小时
        vm.warp(block.timestamp + 23 hours);

        // 创建并完成第二个活动
        (bool success2,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Activity 2",
            "Test Content",
            "0,0",
            block.timestamp + 20 days,
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            proxyFishCakeCoin
        );
        assertTrue(success2);

        FishcakeEventManager(proxyFishcakeEventManager).drop(2, user, 100 * 10 ** 6);

        balanceBefore = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        assertEq(
            balanceBefore, 199_999_910_000_000, "owner should have 199_999_910 FishCakeCoin before activityFinish2"
        );

        console.log("==============================================================================================");
        console.log("balanceBefore", balanceBefore);
        console.log("block.timestamp", block.timestamp);
        // 24小时内不应该获得挖矿奖励
        bool finishSuccess2 = FishcakeEventManager(proxyFishcakeEventManager).activityFinish(2);
        assertTrue(finishSuccess2, "finishSuccess2 should be true");
        balanceAfter = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        assertEq(balanceAfter, 200_000_810_000_000, "owner should have 200_000_810 FishCakeCoin after activityFinish2");

        // 24小时内不应该获得挖矿奖励
        assertEq(balanceAfter, balanceBefore + 900 * 10 ** 6, "Should not get mining reward within 24 hours");

        // 3. 测试24小时后挖矿
        vm.warp(block.timestamp + 25 hours); // 确保超过24小时

        // 创建并完成第三个活动
        (bool success3,) = FishcakeEventManager(proxyFishcakeEventManager).activityAdd(
            "Activity 3",
            "Test Content",
            "0,0",
            block.timestamp + 20 days,
            totalAmount,
            1,
            10,
            0,
            100 * 10 ** 6,
            address(proxyFishCakeCoin)
        );
        assertTrue(success3);

        FishcakeEventManager(proxyFishcakeEventManager).drop(3, user, 100 * 10 ** 6);

        balanceBefore = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        assertEq(
            balanceBefore,
            199_999_810_000_000,
            "owner should have 199_998_910_000000 FishCakeCoin before activityFinish3"
        );

        bool finishSuccess3 = FishcakeEventManager(proxyFishcakeEventManager).activityFinish(3);
        assertTrue(finishSuccess3);
        balanceAfter = FishCakeCoin(proxyFishCakeCoin).balanceOf(owner.addr);
        assertEq(balanceAfter, 200_000_720_000_000, "owner should have 200_000_720 FishCakeCoin after activityFinish3");

        // 24小时后应该能再次获得挖矿奖励
        assertTrue(balanceAfter > balanceBefore + 900 * 10 ** 6, "Should get mining reward after 24 hours");

        vm.stopPrank();
    }
}
