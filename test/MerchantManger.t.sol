// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MerchantManger} from "../src/contracts/core/MerchantManger.sol";
import {FccToken} from "../src/contracts/core/FccToken.sol";

contract MerchantMangerTest is Test {
    address admin = makeAddr("admin");
    address merchant = makeAddr("merchant");
    address user = makeAddr("user");
    MerchantManger public merchantManger;
    FccToken public fct;

    function setUp() public {
        //管理员身份先部署以及铸造基本
        vm.startPrank(admin);
        fct = new FccToken(admin);
        fct.mint(admin, 100000e18);
        fct.mint(merchant, 100000e18);
        merchantManger = new MerchantManger();
        merchantManger.initialize(address(fct));
        vm.stopPrank();
    }

    function testFuzz_SetMinePercent(uint8 amount) public {
        vm.assume(amount < 101);
        vm.startPrank(admin);
        {
            merchantManger.setMinePercent(amount);
        }
        vm.stopPrank();
    }

    function test_AddMineAmt() public {
        //vm.assume(amount<101);
        vm.startPrank(admin);
        //fct.mint(admin, 1e18);
        console.log("admin balance=", fct.balanceOf(address(admin)));
        fct.approve(address(merchantManger), UINT256_MAX);
        uint256 oldData = merchantManger.totalMineAmt();

        {
            merchantManger.addMineAmt(1e18);
            console.log("aaa");
            assertEq(merchantManger.totalMineAmt(), oldData + 1e18);
        }
        vm.stopPrank();
    }

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

    function set_ActivityAdd() public {
        vm.startPrank(merchant);
        {
            fct.approve(address(merchantManger), UINT256_MAX);
            string memory _businessName = "Fishcake Store Grand open";
            string
                memory _activityContent = "2000 FCC even drop to 100 people whovisit store on grand open day";
            string memory _latitudeLongitude = "35.384581,115.664607";
            uint256 _activityDeadLine = 1710592488;

            //平均分 1表示平均获得  2表示随机
            uint8 _dropType = 1;
            //
            uint256 _dropNumber = 1000000;
            //当dropType为1时，填0，为2时，填每份最少领取数量
            uint256 _minDropAmt = 0;
            uint256 _maxDropAmt = 10;
            //根据_maxDropAmt * _dropNumber得到，不用用户输入
            uint256 _totalDropAmts = _maxDropAmt * _dropNumber;
            address _tokenContractAddr = address(fct);
            merchantManger.activityAdd(
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
        }

        vm.stopPrank();
    }

    function test_ActivityAdd() public {
        set_ActivityAdd();
    }

    function test_Drop() public {
        set_ActivityAdd();
        vm.startPrank(merchant);
        {
          console.log("contract before balance=", fct.balanceOf(address(merchantManger)));
          merchantManger.drop(1, address(user), 0);  
          console.log("contract after balance=", fct.balanceOf(address(merchantManger)));
          console.log("user balance=", fct.balanceOf(address(user)));
        }
        vm.stopPrank();
    }
}
