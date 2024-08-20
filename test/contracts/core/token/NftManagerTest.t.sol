// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console} from "forge-std/console.sol";

import {NftManager} from "@contracts/core/token/NftManager.sol";
import {FishCakeCoin} from "@contracts/core/token/FishCakeCoin.sol";
import {NftManagerStorage} from "@contracts/core/token/NftManagerStorage.sol";
import {FishcakeTestHelperTest} from "../../FishcakeTestHelper.t.sol";

contract NftManagerTest is FishcakeTestHelperTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_createNFT_type1() public {
        super.test_FishCakeCoin_PoolAllocate();

        // 调用通过代理合约进行
        NftManager tempNftManager = NftManager(payable(address(proxyNftManager)));
        FishCakeCoin tempFishCakeCoin = FishCakeCoin(address(proxyFishCakeCoin));

        console.log("NftManagerTest test_createNFT_type1 fccTokenAddr:", address(tempNftManager.fccTokenAddr()));
        console.log("NftManagerTest test_createNFT_type1 tokenUsdtAddr:", address(tempNftManager.tokenUsdtAddr()));
        console.log("NftManagerTest test_createNFT_type1 redemptionPoolAddress:", address(tempNftManager.redemptionPoolAddress()));
        console.log("NftManagerTest test_createNFT_type1 merchantValue:", tempNftManager.merchantValue());
        console.log("NftManagerTest test_createNFT_type1 userValue:", tempNftManager.userValue());

        string memory temp_businessName = "temp_businessName";
        string memory temp_description = "temp_description";
        string memory temp_imgUrl = "temp_imgUrl";
        string memory temp_businessAddress = "temp_businessAddress";
        string memory temp_website = "temp_website";
        string memory temp_social = "temp_social";
        uint8 temp_type = 1;

        uint256 before_tempNftManager_fcc = tempFishCakeCoin.FccBalance(address(tempNftManager));
        console.log("NftManagerTest test_createNFT_type1 before_tempNftManager_fcc:", before_tempNftManager_fcc);
        uint256 before_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("NftManagerTest test_createNFT_type1 before_deployerAddress_fcc:", before_deployerAddress_fcc);
        uint256 before_tempNftManager_usdt = usdtToken.balanceOf(address(tempNftManager));
        console.log("NftManagerTest test_createNFT_type1 before_tempNftManager_usdt:", before_tempNftManager_usdt);
        uint256 before_deployerAddress_usdt = usdtToken.balanceOf(address(deployerAddress));
        console.log("NftManagerTest test_createNFT_type1 before_deployerAddress_usdt:", before_deployerAddress_usdt);
        uint256 before_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("NftManagerTest test_createNFT_type1 before_redemptionPool_usdt:", before_redemptionPool_usdt);
        uint256 before_tempId = tempNftManager.getMerchantNTFDeadline(deployerAddress);
        console.log("NftManagerTest test_createNFT_type1 before_tempId:", before_tempId);
        uint256 before_721_count = tempNftManager.balanceOf(deployerAddress);
        console.log("NftManagerTest test_createNFT_type1 before_721_count:", before_721_count);

        vm.startPrank(deployerAddress);
        uint256 usdt_amount = 8e7 + 1;
        console.log("NftManagerTest test_createNFT_type1 usdt_amount:", usdt_amount);
        usdtToken.approve(address(tempNftManager), usdt_amount);
        tempNftManager.createNFT(temp_businessName, temp_description, temp_imgUrl, temp_businessAddress,
            temp_website, temp_social, temp_type);
        vm.stopPrank();

        uint256 after_tempNftManager_fcc = tempFishCakeCoin.FccBalance(address(tempNftManager));
        console.log("NftManagerTest test_createNFT_type1 after_tempNftManager_fcc:", after_tempNftManager_fcc);
        console.log("NftManagerTest test_createNFT_type1 tempNftManager.proMineAmt():", tempNftManager.proMineAmt());
        assertTrue(before_tempNftManager_fcc - tempNftManager.proMineAmt() == after_tempNftManager_fcc, "before_tempNftManager_fcc - tempNftManager.proMineAmt() == after_tempNftManager_fcc");

        uint256 after_deployerAddress_fcc = tempFishCakeCoin.FccBalance(address(deployerAddress));
        console.log("NftManagerTest test_createNFT_type1 after_deployerAddress_fcc:", after_deployerAddress_fcc);
        assertTrue(tempNftManager.proMineAmt() == after_deployerAddress_fcc, "tempNftManager.proMineAmt() == after_deployerAddress_fcc");

        uint256 after_tempNftManager_usdt = usdtToken.balanceOf(address(tempNftManager));
        console.log("NftManagerTest test_createNFT_type1 after_tempNftManager_usdt:", after_tempNftManager_usdt);
        assertTrue(tempNftManager.merchantValue() * 25 / 100 == after_tempNftManager_usdt, "tempNftManager.merchantValue() * 25 / 100 == after_tempNftManager_usdt");

        uint256 after_deployerAddress_usdt = usdtToken.balanceOf(address(deployerAddress));
        console.log("NftManagerTest test_createNFT_type1 after_deployerAddress_usdt:", after_deployerAddress_usdt);
        assertTrue(before_deployerAddress_usdt - tempNftManager.merchantValue() == after_deployerAddress_usdt, "before_deployerAddress_usdt - tempNftManager.merchantValue() == after_deployerAddress_usdt");

        uint256 after_redemptionPool_usdt = usdtToken.balanceOf(address(redemptionPool));
        console.log("NftManagerTest test_createNFT_type1 after_redemptionPool_usdt:", after_redemptionPool_usdt);
        assertTrue(tempNftManager.merchantValue() * 75 / 100 == after_redemptionPool_usdt, "tempNftManager.merchantValue() * 75 / 100 == after_redemptionPool_usdt");

        uint256 after_tempId = tempNftManager.getMerchantNTFDeadline(deployerAddress);
        console.log("NftManagerTest test_createNFT_type1 after_tempId:", after_tempId);
        assertTrue(tempNftManager.validTime() + 1 == after_tempId, "tempNftManager.validTime() + 1 == after_tempId");

        uint256 after_721_count = tempNftManager.balanceOf(deployerAddress);
        console.log("NftManagerTest test_createNFT_type1 after_721_count:", after_721_count);
        assertTrue(1 == after_721_count, "1 == after_721_count");
    }
}
