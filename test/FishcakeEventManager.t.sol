// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console, StdAssertions} from "forge-std/Test.sol";
import {FishcakeEventManager} from "../src/contracts/core/FishcakeEventManager.sol";
import {FccToken} from "../src/contracts/core/FccToken.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {UsdtToken} from "../src/contracts/core/UsdtToken.sol";

import {NFTManager} from "../src/contracts/core/NFTManager.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract FishcakeEventManagerTest is Test {
    using Strings for uint256;
    address admin = makeAddr("admin");
    address merchant = makeAddr("merchant");
    address user = makeAddr("user");
    address redemptionPool = makeAddr("redemptionPool");

    FishcakeEventManager public merchantManger;
    NFTManager public nFTManager;
    FccToken public fct;
    UsdtToken public usdt;

    function setUp() public {
        //Deploying and minting the basic functions as an administrator.
        vm.startPrank(admin);
        fct = new FccToken(admin);
        fct.mint(admin, 10000e18);
        fct.mint(merchant, 10000e18);

        usdt = new UsdtToken(admin);
        usdt.mint(admin, 1000000000e6);
        usdt.mint(merchant, 1000000000e6);
        usdt.mint(user, 1000000000e6);

        //nFTManager = new NFTManager(address(fct), address(usdt));
        //nFTManager = new NFTManager();
        /*Options memory opts;
        opts.unsafeSkipAllChecks = true;
        address nftManagerProxy = Upgrades.deployTransparentProxy(
            "NFTManager.sol",
            admin,
            abi.encodeCall(
                NFTManager.initialize,
                (address(admin), address(fct), address(usdt))
            ),
            opts
        );
        console.log("proxy~:", nftManagerProxy);
        nFTManager = NFTManager(payable(nftManagerProxy));
        */
        nFTManager = new NFTManager(
            address(admin),
            address(fct),
            address(usdt),
            redemptionPool
        );
        //nFTManager.initialize(address(admin),address(fct), address(usdt));
        /*merchantManger = new MerchantManger();
        merchantManger.initialize(
            address(admin),
            address(fct),
            address(nFTManager)
        );*/
        /*
        address merManagerProxy = Upgrades.deployTransparentProxy(
            "MerchantManger.sol",
            admin,
            abi.encodeCall(
                MerchantManger.initialize,
                (address(admin), address(fct), address(nFTManager))
            ),
            opts
        );
        console.log("merManagerProxy proxy~:", merManagerProxy);
        merchantManger = MerchantManger(payable(merManagerProxy));
        */
        merchantManger = new FishcakeEventManager(
            address(admin),
            address(fct),
            address(usdt),
            address(nFTManager)
        );

        fct.approve(address(merchantManger), UINT256_MAX);
        //merchantManger.addMineAmt(1000e18);
        vm.stopPrank();
    }

    /**
     * Fuzz testing - Setting mining percentage.
     
    function testFuzz_SetMinePercent(uint8 amount) public {
        vm.assume(amount < 101);
        vm.startPrank(admin);
        {
            //merchantManger.setMinePercent(amount);
        }
        vm.stopPrank();
    }
*/
    /**
     * Testing the addition of reward pool for merchants' rewards.
     
    function test_AddMineAmt() public {
        //vm.assume(amount<101);
        vm.startPrank(admin);
        //fct.mint(admin, 1e18);
        console.log("admin balance=", fct.balanceOf(address(admin)));
        fct.approve(address(merchantManger), UINT256_MAX);
        uint256 oldData = merchantManger.totalMineAmt();

        {
            merchantManger.addMineAmt(1000e18);
            console.log("aaa");
            assertEq(merchantManger.totalMineAmt(), oldData + 1000e18);
        }
        vm.stopPrank();
    }
*/
    /**
     * fuzz Testing the addition of reward pool for merchants' rewards.
     
    function testFuzz_AddMineAmt(uint256 amount) public {
        vm.assume(amount > 0 && amount < 1e18);
        vm.startPrank(admin);

        {
            fct.approve(address(merchantManger), UINT256_MAX);
            uint256 oldData = merchantManger.totalMineAmt();

            merchantManger.addMineAmt(amount);

            assertEq(merchantManger.totalMineAmt(), oldData + amount);
        }
        vm.stopPrank();
    }
*/
    /*
    Activity details added for reward rule 1.
    */
    function set_ActivityAdd() public returns (bool _ret, uint256 _activityId) {
        vm.startPrank(merchant);
        vm.warp(1716520877);
        {
            fct.approve(address(merchantManger), UINT256_MAX);
            string memory _businessName = "Fishcake Store Grand open";
            string
                memory _activityContent = "2000 FCC even drop to 100 people whovisit store on grand open day";
            string memory _latitudeLongitude = "35.384581,115.664607";
            uint256 _activityDeadLine = 1716550801;


            //Reward rule: 1 represents equal distribution, 2 represents random distribution.
            uint8 _dropType = 1;
            //Number of reward shares.
            uint256 _dropNumber = 10;
            //When dropType is 1, _minDropAmt is set to 0. When it is 2, it is set to the minimum quantity to be received per share.
            uint256 _minDropAmt = 0;
            //When dropType is 1, _maxDropAmt is filled with the quantity of each reward share. When it is 2, it is filled with the maximum quantity to be received per share.
            uint256 _maxDropAmt = 10e18;
            //It is calculated based on _maxDropAmt * _dropNumber and does not require user input.

            uint256 _totalDropAmts = _maxDropAmt * _dropNumber;
            address _tokenContractAddr = address(fct);
            (_ret, _activityId) = merchantManger.activityAdd(
                _businessName,
                _activityContent,
                _latitudeLongitude,
                _activityDeadLine,
                _totalDropAmts,
                _dropType,
                _dropNumber,
                _minDropAmt,
                _maxDropAmt,
                _tokenContractAddr
            );
            //assertTrue(_ret);
            require(_ret, "activityAdd return false");

            (uint256 aaaactivityId, , , , , ) = merchantManger
                .activityInfoExtArrs(_activityId - 1);
            //assertEq(_activityId, aaaactivityId);
            require(_activityId == aaaactivityId, "activityId is not equal");

            //console.log("data:", aaaactivityId);
        }

        vm.stopPrank();
    }

    /*
    Activity details added for reward rule 2
    */
    function set_ActivityAddWithType2()
        public
        returns (bool _ret, uint256 _activityId)
    {
        vm.startPrank(merchant);
        {
            fct.approve(address(merchantManger), UINT256_MAX);
            string memory _businessName = "Fishcake Store Grand open";
            string
                memory _activityContent = "2000 FCC even drop to 100 people whovisit store on grand open day";
            string memory _latitudeLongitude = "35.384581,115.664607";
            uint256 _activityDeadLine = 1710592488;

            //Reward rule: 1 represents equal distribution, 2 represents random distribution.
            uint8 _dropType = 2;
            //Number of reward shares.
            uint256 _dropNumber = 100;
            //When dropType is 1, _minDropAmt is set to 0. When it is 2, it is set to the minimum quantity to be received per share.
            uint256 _minDropAmt = 1e18;
            //When dropType is 1, _maxDropAmt is filled with the quantity of each reward share. When it is 2, it is filled with the maximum quantity to be received per share.
            uint256 _maxDropAmt = 10e18;
            //It is calculated based on _maxDropAmt * _dropNumber and does not require user input.
            uint256 _totalDropAmts = _maxDropAmt * _dropNumber;
            address _tokenContractAddr = address(fct);
            (_ret, _activityId) = merchantManger.activityAdd(
                _businessName,
                _activityContent,
                _latitudeLongitude,
                _activityDeadLine,
                _totalDropAmts,
                _dropType,
                _dropNumber,
                _minDropAmt,
                _maxDropAmt,
                _tokenContractAddr
            );
            assertTrue(_ret);
        }

        vm.stopPrank();
    }

    function test_ActivityAdda() public {
        set_ActivityAdd();
    }

    function test_ActivityAddWhenType2() public {
        set_ActivityAddWithType2();
    }

    /*
    When the reward rule is 1, test the reward claim process
    */
    function test_Drop() public {
        bool _ret;
        uint256 _activityId;
        (_ret, _activityId) = set_ActivityAdd();
        vm.startPrank(merchant);
        //When type is 1, this parameter can be ignored
        uint256 _dropAmt = 0;
        uint256 contractBeforeBalance = fct.balanceOf(address(merchantManger));
        {
            //console.log("contract before balance=",fct.balanceOf(address(merchantManger)));
            merchantManger.drop(_activityId, address(user), _dropAmt);
            uint256 contractAfterBalance = fct.balanceOf(
                address(merchantManger)
            );
            uint256 userBalance = fct.balanceOf(address(user));
            assertEq(userBalance, contractBeforeBalance - contractAfterBalance);
            //console.log("contract after balance=",fct.balanceOf(address(merchantManger)));
            //console.log("user balance=", fct.balanceOf(address(user)));
        }
        vm.stopPrank();
    }

    /*
    When the reward rule is 1, test the process of claiming rewards by claiming all the reward shares
    */
    function test_DropWith100Users() public {
        bool _ret;
        uint256 _activityId;
        //set 100
        (_ret, _activityId) = set_ActivityAdd();
        vm.startPrank(merchant);
        //When type is 1, this parameter can be ignored.
        uint256 _dropAmt = 0;

        {
            //console.log("contract before balance=",fct.balanceOf(address(merchantManger)));
            for (uint256 i = 0; i < 101; i++) {
                uint256 contractBeforeBalance = fct.balanceOf(
                    address(merchantManger)
                );
                address users = makeAddr(i.toString());
                if (i == 100)
                    vm.expectRevert(bytes("Exceeded the number of rewards."));
                merchantManger.drop(_activityId, address(users), _dropAmt);
                uint256 contractAfterBalance = fct.balanceOf(
                    address(merchantManger)
                );
                uint256 userBalance = fct.balanceOf(address(users));
                assertEq(
                    userBalance,
                    contractBeforeBalance - contractAfterBalance
                );
            }

            //console.log("contract after balance=",fct.balanceOf(address(merchantManger)));
            //console.log("user balance=", fct.balanceOf(address(user)));
        }
        vm.stopPrank();
    }

    /*
    When the reward rule is 2, test the process of claiming rewards
    */
    function test_DropWhenType2() public {
        bool _ret;
        uint256 _activityId;
        (_ret, _activityId) = set_ActivityAddWithType2();
        vm.startPrank(merchant);
        //When the type is 2, this parameter represents the quantity of tokens to be claimed as rewards.
        uint256 _dropAmt = 1e18;
        uint256 contractBeforeBalance = fct.balanceOf(address(merchantManger));
        {
            //console.log("contract before balance=",fct.balanceOf(address(merchantManger)));
            merchantManger.drop(_activityId, address(user), _dropAmt);
            uint256 contractAfterBalance = fct.balanceOf(
                address(merchantManger)
            );
            uint256 userBalance = fct.balanceOf(address(user));
            assertEq(userBalance, contractBeforeBalance - contractAfterBalance);
            //console.log("contract after balance=",fct.balanceOf(address(merchantManger)));
            //console.log("user balance=", fct.balanceOf(address(user)));
        }
        vm.stopPrank();
    }

    /*
    When the reward rule is 2, test the process of receiving rewards:
    Claim all the reward shares
    */
    function test_DropWhenType2With100Users() public {
        bool _ret;
        uint256 _activityId;
        //set 100
        (_ret, _activityId) = set_ActivityAddWithType2();
        vm.startPrank(merchant);
        //type为2时，该参数为领取奖励的token数量
        uint256 _dropAmt = 1e18;

        {
            //console.log("contract before balance=",fct.balanceOf(address(merchantManger)));
            for (uint256 i = 0; i < 101; i++) {
                uint256 contractBeforeBalance = fct.balanceOf(
                    address(merchantManger)
                );
                address users = makeAddr(i.toString());
                if (i == 100)
                    vm.expectRevert(bytes("Exceeded the number of rewards."));
                merchantManger.drop(_activityId, address(users), _dropAmt);
                uint256 contractAfterBalance = fct.balanceOf(
                    address(merchantManger)
                );
                uint256 userBalance = fct.balanceOf(address(users));
                assertEq(
                    userBalance,
                    contractBeforeBalance - contractAfterBalance
                );
            }
            //vm.expectRevert(MintPriceNotPaid.selector);
            //console.log("contract after balance=",fct.balanceOf(address(merchantManger)));
            //console.log("user balance=", fct.balanceOf(address(user)));
        }
        vm.stopPrank();
    }

    function test_ActivityFinish() public {
        bool _ret;
        uint256 _activityId;
        console.log(
            "userMerchant before1 balance=",
            fct.balanceOf(address(merchant))
        );
        console.log(
            "contract before1 balance=",
            fct.balanceOf(address(merchantManger))
        );
        (_ret, _activityId) = set_ActivityAdd();
        vm.startPrank(merchant);
        {
            console.log(
                "userMerchant before2 balance=",
                fct.balanceOf(address(merchant))
            );
            console.log(
                "contract before2 balance=",
                fct.balanceOf(address(merchantManger))
            );

            merchantManger.activityFinish(_activityId);
            console.log(
                "contract after3 balance=",
                fct.balanceOf(address(merchantManger))
            );
            console.log(
                "userMerchant after3 balance=",
                fct.balanceOf(address(merchant))
            );
            (
                uint256 aaaactivityId,
                ,
                ,
                ,
                ,
                uint8 activityStatus
            ) = merchantManger.activityInfoExtArrs(_activityId - 1);
            assertEq(2, activityStatus);
            assertEq(_activityId, aaaactivityId);

            /**
             * Finish again,vm.expectRevert(bytes("Activity Status Error."));
             */
            vm.expectRevert(bytes("Activity Status Error."));
            merchantManger.activityFinish(_activityId);

            //console.log("user balance=", fct.balanceOf(address(user)));
        }
        vm.stopPrank();
        //
    }

    /*
    "When the reward rule is 1, test the process of receiving rewards:
    1. Claim all the reward shares.
    2. Interrupt the process at 50 and end it.
    3. Check if both users and merchants can receive mining rewards separately."
    */
    function test_ActivityFinishWith100Users() public {
        console.log(
            "contract begin balance=",
            fct.balanceOf(address(merchantManger)) / 1 ether
        );
        console.log(
            "userMerchant begin balance=",
            fct.balanceOf(address(merchant)) / 1 ether
        );
        console.log(
            "contract begin balance=",
            fct.balanceOf(address(merchantManger)) / 1 ether
        );
        console.log(
            "userMerchant begin balance=",
            fct.balanceOf(address(merchant)) / 1 ether
        );
        bool _ret;
        uint256 _activityId;
        //set 100
        (_ret, _activityId) = set_ActivityAdd();
        vm.startPrank(merchant);
        //"When type is 1, this parameter can be ignored."
        uint256 _dropAmt = 0;

        {
            //console.log("contract before balance=",fct.balanceOf(address(merchantManger)));
            for (uint256 i = 0; i < 101; i++) {
                uint256 contractBeforeBalance = fct.balanceOf(
                    address(merchantManger)
                );
                if (i == 50) {
                    merchantManger.activityFinish(_activityId);
                    console.log(
                        "contract after balance=",
                        fct.balanceOf(address(merchantManger)) / 1 ether
                    );
                    console.log(
                        "userMerchant after balance=",
                        fct.balanceOf(address(merchant)) / 1 ether
                    );
                    /**
                     *  (
                        uint256 activityId,
                        uint256 alreadyDropAmts,
                        uint256 alreadyDropNumber,
                        uint256 businessMinedAmt,
                        uint256 businessMinedWithdrawedAmt,
                        uint8 activityStatus
                    )
                     */

                    (
                        uint256 aaaactivityId,
                        ,
                        ,
                        ,
                        ,
                        uint8 activityStatus
                    ) = merchantManger.activityInfoExtArrs(_activityId - 1);
                    assertEq(2, activityStatus);
                    assertEq(_activityId, aaaactivityId);

                    /**
                     * Finish again,vm.expectRevert(bytes("Activity Status Error."));
                     */
                    vm.expectRevert(bytes("Activity Status Error."));
                    merchantManger.activityFinish(_activityId);

                    return;
                }
                address users = makeAddr(i.toString());
                if (i == 100)
                    vm.expectRevert(bytes("Exceeded the number of rewards."));
                merchantManger.drop(_activityId, address(users), _dropAmt);
                uint256 contractAfterBalance = fct.balanceOf(
                    address(merchantManger)
                );
                uint256 userBalance = fct.balanceOf(address(users));
                assertEq(
                    userBalance,
                    contractBeforeBalance - contractAfterBalance
                );
            }

            //console.log("contract after balance=",fct.balanceOf(address(merchantManger)));
            //console.log("user balance=", fct.balanceOf(address(user)));
        }
        vm.stopPrank();
    }

    /*
    When the reward rule is 1, test the process of receiving rewards:
    Claim all the reward shares.
    End the process and check if both users and merchants can receive mining rewards separately
    */
    function test_ActivityFinishWithAllUsers() public {
        console.log(
            "contract begin balance=",
            fct.balanceOf(address(merchantManger)) / 1 ether
        );
        console.log(
            "userMerchant begin balance=",
            fct.balanceOf(address(merchant)) / 1 ether
        );
        console.log(
            "contract begin balance=",
            fct.balanceOf(address(merchantManger)) / 1 ether
        );
        console.log(
            "userMerchant begin balance=",
            fct.balanceOf(address(merchant)) / 1 ether
        );
        bool _ret;
        uint256 _activityId;
        //set 100
        (_ret, _activityId) = set_ActivityAdd();

        //mint NFT
        test_UserMintWithType1();
        vm.startPrank(merchant);
        //When type is 1, this parameter can be ignored.
        uint256 _dropAmt = 0;

        {
            console.log(
                "merchantManger contract befor balance=",
                fct.balanceOf(address(merchantManger)) / 1 ether
            );
            console.log(
                "merchant user befor balance=",
                fct.balanceOf(address(merchant)) / 1 ether
            );
            for (uint256 i = 0; i < 10; i++) {
                uint256 contractBeforeBalance = fct.balanceOf(
                    address(merchantManger)
                );

                address users = makeAddr(i.toString());
                merchantManger.drop(_activityId, address(users), _dropAmt);
                uint256 contractAfterBalance = fct.balanceOf(
                    address(merchantManger)
                );
                uint256 userBalance = fct.balanceOf(address(users));
                /*assertEqUint(
                    userBalance,
                    contractBeforeBalance - contractAfterBalance
                );*/
                require(
                    userBalance == contractBeforeBalance - contractAfterBalance,
                    "drop error"
                );
            }
            merchantManger.activityFinish(_activityId);
            console.log(
                "merchantManger contract after balance=",
                fct.balanceOf(address(merchantManger)) / 1 ether
            );
            console.log(
                "merchant user after balance=",
                fct.balanceOf(address(merchant)) / 1 ether
            );
        }
        vm.stopPrank();
    }

    function test_UserMintWithType1() public {
        //use merchant account
        vm.startPrank(merchant);
        {
            usdt.approve(address(nFTManager), 80e6);
            string memory _businessName = "im big man";
            string memory _description = "this is bing man";
            string memory _imgUrl = "https://bing.com/img";
            string memory _businessAddress = "budao street";
            string memory _webSite = "https://bing.com";
            string memory _social = "https://bing.com/social";
            uint8 _type = 1;
            (bool _ret, uint256 _tokenId) = nFTManager.createNFT(
                _businessName,
                _description,
                _imgUrl,
                _businessAddress,
                _webSite,
                _social,
                _type
            );

            /*if (_ret) {
                console.log("mint success,block.timestamp:", block.timestamp);
                console.log("mint success,tokenId:", _tokenId);
                console.log(
                    "mint success,user balance:",
                    usdt.balanceOf(address(user))
                );
                console.log(
                    "mint success,nFTManager balance",
                    usdt.balanceOf(address(nFTManager))
                );
                console.log(
                    "mint success,merchantNTFDeadline:",
                    nFTManager.getMerchantNTFDeadline(address(merchant))
                );
                console.log(
                    "mint success,userNTFDeadline:",
                    nFTManager.getUserNTFDeadline(address(merchant))
                );
            }*/
        }
        vm.stopPrank();
    }
}
