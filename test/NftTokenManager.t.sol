// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {NftTokenManager} from "../src/contracts/core/NftTokenManager.sol";

contract NftTokenManagerTest is Test {
    address admin = makeAddr("admin");
    address merchant = makeAddr("merchant");
    address user = makeAddr("user");
    NftTokenManager public nftTokenManager;

    function setUp() public {
        //管理员身份先部署以及铸造基本
        vm.startPrank(admin);
        {
            nftTokenManager = new NftTokenManager(
                10000,
                0xf2871ee0c8b5f914ce57858eb217665feeba93b506630c144ec48ff4c5f868eb
            );
            nftTokenManager.setAllowlistMint(true);
        }
        vm.stopPrank();
    }

    /*
    admin: 0xaA10a84CE7d9AE517a52c6d5cA153b369Af99ecF
    merchant: 0x00655EA989254C13e93C5a1F74C4636b5B9926B5
    user: 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D

Tree
└─ f2871ee0c8b5f914ce57858eb217665feeba93b506630c144ec48ff4c5f868eb
   ├─ ccada90fd39a363d6d9b9e9ee57c0dfd6a65744c7bfc51d7f4247bfb707133a9
   │  ├─ 6de91cef5c39e08c7e70bec1a69357434e1f36389b3410a03c9920a277c405dc
   │  └─ 50c68cbdd99a024fff6479c58a8ae0550c28970e3b6bfeed040bd5034047cc54
   └─ 05b26225916a54a9f7c16388731c332005e6b2f7a59dd996ab3cc9faa8357557
      └─ 05b26225916a54a9f7c16388731c332005e6b2f7a59dd996ab3cc9faa8357557

   
    #0 - 0x6de91cef5c39e08c7e70bec1a69357434e1f36389b3410a03c9920a277c405dc
    Proof
    [
    "0x50c68cbdd99a024fff6479c58a8ae0550c28970e3b6bfeed040bd5034047cc54",
    "0x05b26225916a54a9f7c16388731c332005e6b2f7a59dd996ab3cc9faa8357557"
    ]
    */
    function test_First() public {
        console.log("admin:", address(admin));
        console.log("merchant:", address(merchant));
        console.log("user:", address(user));
    }

    function test_AllowlistMint() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = (
            0x50c68cbdd99a024fff6479c58a8ae0550c28970e3b6bfeed040bd5034047cc54
        );
        proof[1] = (
            0x05b26225916a54a9f7c16388731c332005e6b2f7a59dd996ab3cc9faa8357557
        );
        vm.startPrank(admin);
        {
            console.log("admin:", address(admin));
            nftTokenManager.allowlistMint(proof);
        }
        vm.stopPrank();
        console.log("balanceOf admin:",nftTokenManager.balanceOf(address(admin)));
    }
}
