// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {MerchantManger} from "../src/contracts/core/MerchantManger.sol";
import {NftTokenManager} from "../src/contracts/core/NftTokenManager.sol";

import {FccToken} from "../src/contracts/core/FccToken.sol";

import {UsdtToken} from "../src/contracts/core/UsdtToken.sol";
import {FishcakeCoin} from "../src/contracts/core/token/FishcakeCoin.sol";
import {DirectSalePool} from "../src/contracts/core/sale/DirectSalePool.sol";
import {InvestorSalePool} from "../src/contracts/core/sale/InvestorSalePool.sol";
import {RedemptionPool} from "../src/contracts/core/RedemptionPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {NFTManager} from "../src/contracts/core/NFTManager.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import "forge-std/Script.sol";

import "./BaseScript.sol";

// forge script script/Deployer.s.sol:TreasureDeployer --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast -vvvv
//forge script script/Deployer.s.sol:PrivacyContractsDeployer --rpc-url $MUMBAI_RPC_URL --broadcast -vvvv
//forge script script/Deployer.s.sol:PrivacyContractsDeployer --rpc-url $MUMBAI_RPC_URL --broadcast --account a2 -vvvv
/*
Owner: 0x0e730881866fb6d9AB69B64e8Bf8a6496b94370e
Airdrop: 0xC0A3f938D1CaA93646B3b7DF2C636D7b0CCDaDa7
Foundation: 0x80FD2911096998c4be0B9e84316F42d99F8fa0Da
*/
contract PrivacyContractsDeployer is BaseScript {
    function run() external broadcaster {
        // todo: write deploy script here
        /* test data
        FccToken fct = new FccToken(deployer);
        fct.mint(deployer, 1000000000e18);
        console.log("The Deployer address:", deployer);
        console.log("FccToken deployed on %s", address(fct));

        UsdtToken usdt = new UsdtToken(deployer);
        usdt.mint(deployer, 1000000000e18);
        console.log("The Deployer address:", deployer);
        console.log("UsdtToken deployed on %s", address(usdt));
        */
        address Owner = 0x0e730881866fb6d9AB69B64e8Bf8a6496b94370e;
        address Airdrop = 0xC0A3f938D1CaA93646B3b7DF2C636D7b0CCDaDa7;
        address Foundation = 0x80FD2911096998c4be0B9e84316F42d99F8fa0Da;
        FishcakeCoin fct = new FishcakeCoin();
        IERC20 usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        console.log("The Deployer address:", deployer);
        console.log("FccToken deployed on %s", address(fct));
        console.log("UsdtToken deployed on %s", address(usdt));
        RedemptionPool redemptionPool = new RedemptionPool(address(fct));
        DirectSalePool directSalePool = new DirectSalePool(
            deployer,
            address(redemptionPool)
        );
        InvestorSalePool investorSalePool = new InvestorSalePool(
            deployer,
            address(redemptionPool)
        );

        console.log("redemptionPool deployed on %s", address(redemptionPool));
        console.log("directSalePool deployed on %s", address(directSalePool));
        console.log(
            "investorSalePool deployed on %s",
            address(investorSalePool)
        );
        NFTManager nFTManager = new NFTManager(
            deployer,
            address(fct),
            address(usdt),
            address(redemptionPool)
        );
        MerchantManger merchantManger = new MerchantManger(
            deployer,
            address(fct),
            address(nFTManager)
        );
        console.log("NFTManager deployed on %s", address(nFTManager));
        console.log("MerchantManger deployed on %s", address(merchantManger));

        //_MiningPool, _DirectSalePool, _InvestorSalePool, _NFTSalesRewardsPool, _EarlyStageAirdropsPool, _FoundationPool
        fct.setPoolAddress(
            address(merchantManger),
            address(directSalePool),
            address(investorSalePool),
            address(nFTManager),
            Airdrop,
            Foundation
        );
        //mint coin
        fct.PoolAllocation();

        fct.approve(address(merchantManger), 10000e18);
        usdt.approve(address(nFTManager), 80e18);
        //mint nft  80u
        mintNft(nFTManager);

        bool _ret;
        uint256 _activityId;
        address _userAccount = 0x50547aC9b9b3C0717689F7691c2AaB2EF66B6BfE;
        (_ret, _activityId) = set_ActivityAdd(merchantManger, address(fct));

        merchantManger.drop(_activityId, _userAccount, 100e18);
        merchantManger.activityFinish(_activityId);
        vm.label(address(nFTManager), "nFTManager");
        vm.label(address(merchantManger), "merchantManger");

        /* NftTokenManager nftTokenManager = new NftTokenManager(
                10000e18,
                0xb17bfe8affa15102cfa29f4c02627b22b55c6066a572623d18bfc0783f7fd627
            );
        console.log("NftTokenManager deployed on %s", address(nftTokenManager));
        nftTokenManager.setAllowlistMint(true);


        bytes32[] memory proof = new bytes32[](2);
        proof[0] = (
            0x39472b1591fd97b603a76c1e52b92e3f86af4031078c85ff006da4627c6972d8
        );
        proof[1] = (
            0x460ccc85233ad1e14f3cafdd1d5e64fc24cd8a0f163248ed218051d12f2a9b05
        );
        nftTokenManager.allowlistMint(proof);
*/
    }

    function set_ActivityAdd(
        MerchantManger merchantManger,
        address fct
    ) public returns (bool _ret, uint256 _activityId) {
        string memory _businessName = "Fishcake Store Grand open";
        string
            memory _activityContent = "2000 FCC even drop to 100 people whovisit store on grand open day";
        string memory _latitudeLongitude = "35.384581,115.664607";
        uint256 _activityDeadLine = 1710592488;

        //奖励规则：1表示平均获得  2表示随机
        uint8 _dropType = 1;
        //奖励份数
        uint256 _dropNumber = 10;
        //当dropType为1时，_minDropAmt填0，为2时，填每份最少领取数量
        uint256 _minDropAmt = 0;
        //当dropType为1时，_maxDropAmt填每份奖励数量，为2时，填每份最多领取数量
        uint256 _maxDropAmt = 100e18;
        //根据_maxDropAmt * _dropNumber得到，不用用户输入
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
    }

    function mintNft(NFTManager nFTManager) public {
        string memory _businessName = "im big man";
        string memory _description = "this is bing man";
        string memory _imgUrl = "https://bing.com/img";
        string memory _businessAddress = "budao street";
        string memory _webSite = "https://bing.com";
        string memory _social = "https://bing.com/social";
        uint8 _type = 1;
        nFTManager.mintNewEvent(
            _businessName,
            _description,
            _imgUrl,
            _businessAddress,
            _webSite,
            _social,
            _type
        );
    }
}
