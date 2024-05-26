// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {NFTManager} from "../src/contracts/core/NFTManager.sol";
import {NFTManagerUpgrades} from "../src/test/NFTManagerUpgrades.sol";
import {UsdtToken} from "../src/contracts/core/UsdtToken.sol";
import {FccToken} from "../src/contracts/core/FccToken.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract NFTManagerTest is Test {
    address admin = makeAddr("admin");
    address merchant = makeAddr("merchant");
    address user = makeAddr("user");
    address redemptionPool = makeAddr("redemptionPool");
    NFTManager public nFTManager;
    FccToken public fct;
    UsdtToken public usdt;

    function setUp() public {
        //管理员身份先部署以及铸造基本
        vm.startPrank(admin);
        {
            fct = new FccToken(admin);
            fct.mint(admin, 10000e18);
            fct.mint(merchant, 10000e18);

            usdt = new UsdtToken(admin);
            usdt.mint(admin, 66666666e6);
            usdt.mint(merchant, 66666666e6);
            usdt.mint(user, 66666666e6);
            /*
            Options memory opts;
            opts.unsafeSkipAllChecks = true;
            address proxy = Upgrades.deployTransparentProxy(
                "NFTManager.sol",
                admin,
                abi.encodeCall(
                    NFTManager.initialize,
                    (address(admin), address(fct), address(usdt))
                ),
                opts
            );
            console.log("proxy~:", proxy);
        */
            //bytes32 ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
            //address admin = address(uint160(uint256(bytes32(vm.load(address(proxy), ADMIN_SLOT)))));

            //nFTManager = new NFTManager(address(fct), address(usdt));
            //console.log("nftManager:", nFTManager);
            //nFTManager = NFTManager(payable(proxy));
            //nFTManager.initialize(address(admin));
            nFTManager = new NFTManager(
                address(admin),
                address(fct),
                address(usdt),
                redemptionPool
            );
            fct.mint(address(nFTManager), 100000000e18);
        }
        vm.stopPrank();
    }

    function test_First() public view {
        console.log("admin:", address(admin));
        console.log("merchant:", address(merchant));
        console.log("user:", address(user));
    }

    function test_AllowlistMint() public {
        vm.startPrank(admin);
        {}
        vm.stopPrank();
    }

    function test_setUriPrefix() public {
        vm.startPrank(admin);
        {
            nFTManager.setUriPrefix(
                "https://scarlet-tough-cat-815.mypinata.cloud/ipfs/QmbJtntg8qeGvNZRcJTY3msJ8CUHMx11jGR6aCsPQ88mYv/"
            );
            console.log("uriPrefix:", nFTManager.uriPrefix());
        }
        vm.stopPrank();
    }

    function test_UserMint() public {
        test_setUriPrefix();
        //use user account
        vm.startPrank(user);
        {
            usdt.approve(address(nFTManager), 8e6);
            string memory _businessName = "im big man";
            string memory _description = "this is bing man";
            string memory _imgUrl = "https://bing.com/img";
            string memory _businessAddress = "budao street";
            string memory _webSite = "https://bing.com";
            string memory _social = "https://bing.com/social";
            uint8 _type = 2;
            (bool _ret, uint256 _tokenId) = nFTManager.createNFT(
                _businessName,
                _description,
                _imgUrl,
                _businessAddress,
                _webSite,
                _social,
                _type
            );

            if (_ret) {
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
                    "mint success,redemptionPool balance",
                    usdt.balanceOf(address(redemptionPool))
                );
                console.log(
                    "mint success,merchantNTFDeadline:",
                    nFTManager.getMerchantNTFDeadline(address(user))
                );
                console.log(
                    "mint success,userNTFDeadline:",
                    nFTManager.getUserNTFDeadline(address(user))
                );
            }
            /*
            (bool _ret1, uint256 _tokenId1) = nFTManager.mint(
                _businessName,
                _description,
                _imgUrl,
                _businessAddress,
                _webSite,
                _social,
                _type
            );

            if (_ret1) {
                console.log("mint success", _tokenId1);
                console.log("mint success", usdt.balanceOf(address(user)));
                console.log(
                    "mint success",
                    usdt.balanceOf(address(nFTManager))
                );
            }*/
            string memory tokenUri = nFTManager.tokenURI(_tokenId);
            console.log("tokenUri:", tokenUri);
        }
        vm.stopPrank();
    }

    function test_UserMintWithType1() public {
        test_setUriPrefix();
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
            uint8 _type = 2;
            (bool _ret, uint256 _tokenId) = nFTManager.createNFT(
                _businessName,
                _description,
                _imgUrl,
                _businessAddress,
                _webSite,
                _social,
                _type
            );

            if (_ret) {
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
                    "mint success,redemptionPool balance",
                    usdt.balanceOf(address(redemptionPool))
                );
                console.log(
                    "mint success,merchantNTFDeadline:",
                    nFTManager.getMerchantNTFDeadline(address(merchant))
                );
                console.log(
                    "mint success,userNTFDeadline:",
                    nFTManager.getUserNTFDeadline(address(merchant))
                );
            }
            string memory tokenUri = nFTManager.tokenURI(_tokenId);
            console.log("tokenUri:", tokenUri);
        }
        vm.stopPrank();
    }

    function test_UserMintWithOrtherType() public {
        vm.startPrank(user);
        {
            usdt.approve(address(nFTManager), 8e6);
            string memory _businessName = "im big man";
            string memory _description = "this is bing man";
            string memory _imgUrl = "https://bing.com/img";
            string memory _businessAddress = "budao street";
            string memory _webSite = "https://bing.com";
            string memory _social = "https://bing.com/social";
            uint8 _type = 3;
            vm.expectRevert(bytes("Type Error."));
            nFTManager.createNFT(
                _businessName,
                _description,
                _imgUrl,
                _businessAddress,
                _webSite,
                _social,
                _type
            );
        }
        vm.stopPrank();
    }

    function test_UserMintWithNoApprove() public {
        vm.startPrank(user);
        {
            //usdt.approve(address(nFTManager), 16e6);
            string memory _businessName = "im big man";
            string memory _description = "this is bing man";
            string memory _imgUrl = "https://bing.com/img";
            string memory _businessAddress = "budao street";
            string memory _webSite = "https://bing.com";
            string memory _social = "https://bing.com/social";
            uint8 _type = 2;
            vm.expectRevert(bytes("Approve token not enough Error."));
            nFTManager.createNFT(
                _businessName,
                _description,
                _imgUrl,
                _businessAddress,
                _webSite,
                _social,
                _type
            );
        }
        vm.stopPrank();
    }

    function test_withdrawUTokenWithOrthers() public {
        test_UserMint();
        vm.startPrank(user);
        {
            vm.expectRevert(bytes("Ownable: caller is not the owner"));
            nFTManager.withdrawUToken(address(usdt), address(user), 16e6);
        }
        vm.stopPrank();
    }

    function test_withdrawUTokenWithToMoreValue() public {
        test_UserMint();
        vm.startPrank(admin);
        {
            console.log("before balance", usdt.balanceOf(address(admin)));
            //vm.expectRevert(bytes("Balance not enough."));
            nFTManager.withdrawUToken(address(usdt), address(admin), 1000e6);
            console.log("after balance", usdt.balanceOf(address(admin)));
        }
        vm.stopPrank();
    }

    function test_UpgradesContract() public {
        test_UserMint();
        vm.startPrank(admin);
        {
            //console.log("before balance", usdt.balanceOf(address(admin)));
            Options memory opts;
            opts.unsafeSkipAllChecks = true;
            Upgrades.upgradeProxy(
                address(nFTManager),
                "NFTManagerUpgrades.sol:NFTManagerUpgrades",
                "",
                address(admin)
            );
            NFTManagerUpgrades up = NFTManagerUpgrades(address(nFTManager));
            console.log("proxy2222~address:", address(nFTManager));
            console.log(
                "after up getMerchantNTFDeadline:",
                up.getUserNTFDeadline(user)
            );
        }
        vm.stopPrank();
    }
}
