// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console} from "forge-std/console.sol";
import "@openzeppelin-upgrades/contracts/token/ERC20/ERC20Upgradeable.sol";

import {FishcakeEventManager} from "@contracts/core/FishcakeEventManager.sol";
import {FishCakeCoin} from "@contracts/core/token/FishCakeCoin.sol";

import {FishcakeTestHelperTest} from "../FishcakeTestHelper.t.sol";
import {NftManagerTest} from "./token/NftManagerTest.t.sol";

contract FishcakeEventManagerTest is NftManagerTest {

    function setUp() public virtual override {
        super.setUp();
    }
//    修改前
//    require(
//        block.timestamp < _activityDeadLine &&
//        _activityDeadLine < block.timestamp + maxDeadLine,
//        "FishcakeEventManager activityAdd: Activity DeadLine Error."
//    );
//    修改后
//    require(
//        _activityDeadLine < block.timestamp + maxDeadLine,
//        "FishcakeEventManager activityAdd: Activity DeadLine Error."
//    );

//    修改前
//    if ( isMint && ifReward() && iNFTManager.getMerchantNTFDeadline(_msgSender()) > block.timestamp || iNFTManager.getUserNTFDeadline(_msgSender()) > block.timestamp ) {
//    修改后
//    if ( isMint && ifReward()) {

    function test_activity() public {
//        NftManagerTest nftManagerTest = new NftManagerTest();
        test_createNFT_type1();

        FishCakeCoin tempFishCakeCoin = FishCakeCoin(address(proxyFishCakeCoin));
        FishcakeEventManager tempFishcakeEven = FishcakeEventManager(address(proxyFishcakeEventManager));

        console.log("FishcakeEventManagerTest test_activity block.timestamp:", block.timestamp);
        console.log("FishcakeEventManagerTest test_activity block.timestamp + maxDeadLine:", block.timestamp + tempFishcakeEven.maxDeadLine());

        string memory temp_businessName = "temp_businessName";
        string memory temp_activityContent = "temp_activityContent";
        string memory temp_latitudeLongitude = "temp_latitudeLongitude";
        // 活动截至时间
        uint256 temp_activityDeadLine = 1;
        // 活动的总奖励金额
        uint256 temp_totalDropAmts = 10e5;
        console.log("FishcakeEventManagerTest test_activity temp_totalDropAmts:", temp_totalDropAmts);
        // 奖励类型，1 固定，2 随机
        uint8 temp_dropType = 1;
        // 奖励的次数，或者人数
        uint256 temp_dropNumber = 2;
        console.log("FishcakeEventManagerTest test_activity temp_dropNumber:", temp_dropNumber);
        // 最小单次奖励金额
        uint256 temp_minDropAmt = 5e5;
        // 最大单次奖励金额
        uint256 temp_maxDropAmt = 5e5;
        // 奖励所使用的代币合约地址
        address temp_tokenContractAddr = address(proxyFishCakeCoin);

        console.log("FishcakeEventManagerTest test_activity totalDropAmts V2:", temp_dropNumber * temp_maxDropAmt);

        IERC20 erc20 = IERC20(temp_tokenContractAddr);
        console.log("FishcakeEventManagerTest test_activity erc20 before activityAdd:", erc20.balanceOf(deployerAddress));

        vm.startPrank(deployerAddress);
        uint256 fcc_amount = temp_totalDropAmts;
        erc20.approve(address(tempFishcakeEven), fcc_amount);
        (bool success, uint256 activityId) = tempFishcakeEven.activityAdd(temp_businessName, temp_activityContent, temp_latitudeLongitude,
            temp_activityDeadLine, temp_totalDropAmts, temp_dropType, temp_dropNumber, temp_minDropAmt,
            temp_maxDropAmt, temp_tokenContractAddr);
        vm.stopPrank();
        console.log("FishcakeEventManagerTest test_activity activityAdd success:", success);
        console.log("FishcakeEventManagerTest test_activity activityAdd activityId:", activityId);
        assertTrue(success == true, "activityAdd not success");
        console.log("FishcakeEventManagerTest test_activity erc20 after activityAdd:", erc20.balanceOf(deployerAddress));

//        一共两份奖励，根据注释测试进度即可
        address drop_account_1 = address(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
        address drop_account_2 = address(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);
        uint256 drop_drop_amount = 5e5;

        console.log("FishcakeEventManagerTest test_activity erc20 drop_account_1 before:", erc20.balanceOf(drop_account_1));
        console.log("FishcakeEventManagerTest test_activity erc20 drop_1 tempFishcakeEven before:", erc20.balanceOf(address(tempFishcakeEven)));
        vm.startPrank(address(deployerAddress));
        erc20.approve(address(drop_account_1), drop_drop_amount);
        bool success_1 = tempFishcakeEven.drop(activityId, drop_account_1, drop_drop_amount);
        vm.stopPrank();
        console.log("FishcakeEventManagerTest test_activity drop success_1:", success_1);
        console.log("FishcakeEventManagerTest test_activity erc20 drop_account_1 after:", erc20.balanceOf(drop_account_1));
        console.log("FishcakeEventManagerTest test_activity erc20 drop_1 tempFishcakeEven after:", erc20.balanceOf(address(tempFishcakeEven)));

        console.log("FishcakeEventManagerTest test_activity erc20 drop_account_2 before:", erc20.balanceOf(drop_account_2));
        console.log("FishcakeEventManagerTest test_activity erc20 drop_2 tempFishcakeEven before:", erc20.balanceOf(address(tempFishcakeEven)));
        vm.startPrank(address(deployerAddress));
        erc20.approve(address(drop_account_2), drop_drop_amount);
        bool success_2 = tempFishcakeEven.drop(activityId, drop_account_2, drop_drop_amount);
        vm.stopPrank();
        console.log("FishcakeEventManagerTest test_activity drop success_2:", success_2);
        console.log("FishcakeEventManagerTest test_activity erc20 drop_account_2 after:", erc20.balanceOf(drop_account_2));
        console.log("FishcakeEventManagerTest test_activity erc20 drop_2 tempFishcakeEven after:", erc20.balanceOf(address(tempFishcakeEven)));

        console.log("FishcakeEventManagerTest test_activity erc20 owner before:", erc20.balanceOf(deployerAddress));
        vm.startPrank(address(deployerAddress));
        bool success_activityFinish = tempFishcakeEven.activityFinish(activityId);
        vm.stopPrank();
        console.log("FishcakeEventManagerTest test_activity erc20 owner after:", erc20.balanceOf(deployerAddress));

        console.log("FishcakeEventManagerTest test_activity activityFinish");

    }

}
