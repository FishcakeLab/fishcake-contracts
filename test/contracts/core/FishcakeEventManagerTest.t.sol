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
//    In order to run a test case, the following code needs to be modified
//    change 1 before
//    require(
//        block.timestamp < _activityDeadLine &&
//        _activityDeadLine < block.timestamp + maxDeadLine,
//        "FishcakeEventManager activityAdd: Activity DeadLine Error."
//    );
//    change 1 after
//    require(
//        _activityDeadLine < block.timestamp + maxDeadLine,
//        "FishcakeEventManager activityAdd: Activity DeadLine Error."
//    );

//    change 2 before
//    if ( isMint && ifReward() && iNFTManager.getMerchantNTFDeadline(_msgSender()) > block.timestamp || iNFTManager.getUserNTFDeadline(_msgSender()) > block.timestamp ) {
//    change 2 after
//    if ( isMint && ifReward()) {

    function test_activity() public {
        test_createNFT_type1();

        FishCakeCoin tempFishCakeCoin = FishCakeCoin(address(proxyFishCakeCoin));
        FishcakeEventManager tempFishcakeEven = FishcakeEventManager(address(proxyFishcakeEventManager));

        console.log("FishcakeEventManagerTest test_activity block.timestamp:", block.timestamp);
        console.log("FishcakeEventManagerTest test_activity block.timestamp + maxDeadLine:", block.timestamp + tempFishcakeEven.maxDeadLine());

        string memory temp_businessName = "temp_businessName";
        string memory temp_activityContent = "temp_activityContent";
        string memory temp_latitudeLongitude = "temp_latitudeLongitude";
        // activity DeadLine
        uint256 temp_activityDeadLine = 1;
        // activity Total Rewards
        uint256 temp_totalDropAmts = 10e5;
        console.log("FishcakeEventManagerTest test_activity temp_totalDropAmts:", temp_totalDropAmts);
        // dropType: 1 Fixed rewards, 2 Random rewards
        uint8 temp_dropType = 1;
        // Number of rewards
        uint256 temp_dropNumber = 2;
        console.log("FishcakeEventManagerTest test_activity temp_dropNumber:", temp_dropNumber);
        // Minimum single reward
        uint256 temp_minDropAmt = 5e5;
        // maximum single reward
        uint256 temp_maxDropAmt = 5e5;
        // token contract address used for the reward
        address temp_tokenContractAddr = address(proxyFishCakeCoin);

//        uint256 totalDropAmts = temp_dropNumber * temp_maxDropAmt;
//        console.log("FishcakeEventManagerTest test_activity totalDropAmts:", totalDropAmts);

        IERC20 erc20 = IERC20(temp_tokenContractAddr);
        uint256 before_deployerAddress_balance = erc20.balanceOf(deployerAddress);
        console.log("FishcakeEventManagerTest test_activity activityAdd before_deployerAddress_balance:", before_deployerAddress_balance);

        vm.startPrank(deployerAddress);
        uint256 fcc_amount = temp_totalDropAmts;
        erc20.approve(address(tempFishcakeEven), fcc_amount);
        (bool success, uint256 activityId) = tempFishcakeEven.activityAdd(temp_businessName, temp_activityContent, temp_latitudeLongitude,
            temp_activityDeadLine, temp_totalDropAmts, temp_dropType, temp_dropNumber, temp_minDropAmt,
            temp_maxDropAmt, temp_tokenContractAddr);
        vm.stopPrank();

        console.log("FishcakeEventManagerTest test_activity activityAdd success:", success);
        console.log("FishcakeEventManagerTest test_activity activityAdd activityId:", activityId);
        assertTrue(success == true, "activityAdd is success");
        assertTrue(activityId == 1, "activityAdd is 1");

        uint256 after_deployerAddress_balance = erc20.balanceOf(deployerAddress);
        console.log("FishcakeEventManagerTest test_activity activityAdd after_deployerAddress_balance:", after_deployerAddress_balance);
        assertTrue(after_deployerAddress_balance == (before_deployerAddress_balance - fcc_amount), "after_deployerAddress_balance == (before_deployerAddress_balance - fcc_amount)");

        address drop_account_1 = address(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
//        address drop_account_2 = address(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);
        uint256 drop_drop_amount = 5e5;
        uint256 before_drop_account_1_balance = erc20.balanceOf(drop_account_1);
        uint256 before_tempFishcakeEven_balance_1 = erc20.balanceOf(address(tempFishcakeEven));

        console.log("FishcakeEventManagerTest test_activity drop_1 before_drop_account_1_balance:", before_drop_account_1_balance);
        console.log("FishcakeEventManagerTest test_activity drop_1 before_tempFishcakeEven_balance_1:", before_tempFishcakeEven_balance_1);
        vm.startPrank(address(deployerAddress));
//        erc20.approve(address(drop_account_1), drop_drop_amount);
        bool success_1 = tempFishcakeEven.drop(activityId, drop_account_1, drop_drop_amount);
        vm.stopPrank();
        console.log("FishcakeEventManagerTest test_activity drop success_1:", success_1);
        assertTrue(success_1 == true, "drop 1 is success");
        uint256 after_drop_account_1_balance = erc20.balanceOf(drop_account_1);
        uint256 after_tempFishcakeEven_balance_1 = erc20.balanceOf(address(tempFishcakeEven));
        console.log("FishcakeEventManagerTest test_activity drop_1 after_drop_account_1_balance:", after_drop_account_1_balance);
        console.log("FishcakeEventManagerTest test_activity drop_1 after_tempFishcakeEven_balance_1:", after_tempFishcakeEven_balance_1);

        assertTrue(after_drop_account_1_balance == (before_drop_account_1_balance + drop_drop_amount), "after_drop_account_1_balance == (before_drop_account_1_balance + drop_drop_amount)");
        assertTrue(after_tempFishcakeEven_balance_1 == (before_tempFishcakeEven_balance_1 - drop_drop_amount), "after_tempFishcakeEven_balance_1 == (before_tempFishcakeEven_balance_1 - drop_drop_amount)");

//
//        !!!! If you cancel the annotation, you need to recalculate the temp_finish_result
//
//        console.log("FishcakeEventManagerTest test_activity erc20 drop_account_2 before:", erc20.balanceOf(drop_account_2));
//        console.log("FishcakeEventManagerTest test_activity erc20 drop_2 tempFishcakeEven before:", erc20.balanceOf(address(tempFishcakeEven)));
//        vm.startPrank(address(deployerAddress));
//        erc20.approve(address(drop_account_2), drop_drop_amount);
//        bool success_2 = tempFishcakeEven.drop(activityId, drop_account_2, drop_drop_amount);
//        vm.stopPrank();
//        console.log("FishcakeEventManagerTest test_activity drop success_2:", success_2);
//        console.log("FishcakeEventManagerTest test_activity erc20 drop_account_2 after:", erc20.balanceOf(drop_account_2));
//        console.log("FishcakeEventManagerTest test_activity erc20 drop_2 tempFishcakeEven after:", erc20.balanceOf(address(tempFishcakeEven)));

        uint256 before_activityFinish_deployerAddress_balance = erc20.balanceOf(deployerAddress);
        console.log("FishcakeEventManagerTest test_activity before_activityFinish_deployerAddress_balance:", before_activityFinish_deployerAddress_balance);

        vm.startPrank(address(deployerAddress));
        bool success_activityFinish = tempFishcakeEven.activityFinish(activityId);
        vm.stopPrank();

        console.log("FishcakeEventManagerTest test_activity activityFinish success_activityFinish:", success_activityFinish);
        assertTrue(success_activityFinish == true, "success_activityFinish is success");

        uint256 after_activityFinish_deployerAddress_balance = erc20.balanceOf(deployerAddress);
        console.log("FishcakeEventManagerTest test_activity after_activityFinish_deployerAddress_balance:", after_activityFinish_deployerAddress_balance);
//        Final reward = Remaining amount + Mining rewards
        uint256 temp_finish_result = 25e4;
        console.log("FishcakeEventManagerTest test_activity temp_finish_result:", temp_finish_result);
        assertTrue(after_activityFinish_deployerAddress_balance == (before_activityFinish_deployerAddress_balance + drop_drop_amount + 25e4), "after_activityFinish_deployerAddress_balance == (before_activityFinish_deployerAddress_balance + drop_drop_amount + 25e4)");

        console.log("FishcakeEventManagerTest test_activity activityFinish");
    }

}
