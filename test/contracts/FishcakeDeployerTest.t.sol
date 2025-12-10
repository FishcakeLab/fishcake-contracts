// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "@openzeppelin-foundry-upgrades/Upgrades.sol";

import {RedemptionPool} from "@contracts/core/RedemptionPool.sol";
import {FishCakeCoin} from "@contracts/core/token/FishCakeCoin.sol";
import {DirectSalePool} from "../../src/contracts/history/DirectSalePool.sol";
import {InvestorSalePool} from "@contracts/core/sale/InvestorSalePool.sol";
import {IInvestorSalePool} from "@contracts/interfaces/IInvestorSalePool.sol";
import {NftManagerV5} from "@contracts/core/token/NftManagerV5.sol";
import {FishcakeEventManagerV2} from "../../src/contracts/core/FishcakeEventManagerV2.sol";
import {UsdtERC20TestHelper} from "./UsdtERC20TestHelper.sol";

contract FishcakeDeployerTest is Test {
    address internal constant deployerAddress =
        address(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);
    //    local deploy erc20 token
    UsdtERC20TestHelper public usdtToken;
    address public usdtTokenAddress;

    RedemptionPool public redemptionPool;

    // ========= can upgrade ===========
    FishCakeCoin public fishCakeCoin;
    address public proxyFishCakeCoin;
    DirectSalePool public directSalePool;
    address public proxyDirectSalePool;
    InvestorSalePool public investorSalePool;
    address public proxyInvestorSalePool;
    address public proxyNftManagerV5;
    FishcakeEventManagerV2 public fishcakeEventManager;
    address public proxyFishcakeEventManager;

    //performs basic deployment before each test
    function setUp() public virtual {
        usdtToken = new UsdtERC20TestHelper(
            "TestToken",
            "TTK",
            12345678910 * 1e18,
            deployerAddress
        );
        console.log("deploy usdtToken:", address(usdtToken));
        usdtTokenAddress = address(usdtToken);

        try this._deployFishcakeContractsLocal() {
            console.log("FishcakeDeployer setUp: success");
        } catch {
            console.log("FishcakeDeployer setUp: fail");
        }
    }

    function _deployFishcakeContractsLocal() external {
        vm.startBroadcast(deployerAddress);

        fishCakeCoin = new FishCakeCoin();
        proxyFishCakeCoin = Upgrades.deployTransparentProxy(
            "FishCakeCoin.sol:FishCakeCoin",
            deployerAddress,
            abi.encodeWithSelector(
                FishCakeCoin.initialize.selector,
                deployerAddress,
                address(0)
            )
        );
        console.log("deploy fishCakeCoin:", address(fishCakeCoin));
        console.log("deploy proxyFishCakeCoin:", address(proxyFishCakeCoin));

        // can not upgrade
        redemptionPool = new RedemptionPool(
            address(proxyFishCakeCoin),
            address(usdtToken)
        );
        console.log("deploy redemptionPool:", address(redemptionPool));

        directSalePool = new DirectSalePool();
        proxyDirectSalePool = Upgrades.deployTransparentProxy(
            "DirectSalePool.sol:DirectSalePool",
            deployerAddress,
            abi.encodeWithSelector(
                DirectSalePool.initialize.selector,
                deployerAddress,
                proxyFishCakeCoin,
                redemptionPool,
                usdtTokenAddress
            )
        );
        console.log("deploy directSalePool:", address(directSalePool));
        console.log(
            "deploy proxyDirectSalePool:",
            address(proxyDirectSalePool)
        );

        investorSalePool = new InvestorSalePool();
        proxyInvestorSalePool = Upgrades.deployTransparentProxy(
            "InvestorSalePool.sol:InvestorSalePool",
            deployerAddress,
            abi.encodeWithSelector(
                InvestorSalePool.initialize.selector,
                deployerAddress,
                proxyFishCakeCoin,
                redemptionPool,
                usdtTokenAddress
            )
        );
        console.log("deploy investorSalePool:", address(investorSalePool));
        console.log(
            "deploy proxyInvestorSalePool:",
            address(proxyInvestorSalePool)
        );
        console.log(
            "deploy InvestorSalePool fishCakeCoin :",
            address(
                InvestorSalePool(address(proxyInvestorSalePool)).fishCakeCoin()
            )
        );
        console.log(
            "deploy InvestorSalePool redemptionPool :",
            address(
                InvestorSalePool(address(proxyInvestorSalePool))
                    .redemptionPool()
            )
        );
        console.log(
            "deploy InvestorSalePool tokenUsdtAddress :",
            address(
                InvestorSalePool((address(proxyInvestorSalePool)))
                    .tokenUsdtAddress()
            )
        );

        fishcakeEventManager = new FishcakeEventManagerV2();
        proxyFishcakeEventManager = Upgrades.deployTransparentProxy(
            "FishcakeEventManager.sol:FishcakeEventManager",
            deployerAddress,
            abi.encodeWithSelector(
                FishcakeEventManagerV2.initialize.selector,
                deployerAddress,
                proxyFishCakeCoin,
                usdtTokenAddress,
                proxyNftManagerV5
            )
        );
        console.log(
            "deploy fishcakeEventManager:",
            address(fishcakeEventManager)
        );
        console.log(
            "deploy proxyFishcakeEventManager:",
            address(proxyFishcakeEventManager)
        );
        console.log(
            "deploy proxyFishcakeEventManager:",
            address(proxyFishcakeEventManager)
        );
        console.log(
            "deploy proxyFishcakeEventManager isMint :",
            FishcakeEventManagerV2(address(proxyFishcakeEventManager)).isMint()
        );
        console.log(
            "deploy proxyFishcakeEventManager minePercent :",
            FishcakeEventManagerV2(address(proxyFishcakeEventManager))
                .minePercent()
        );
        console.log(
            "deploy proxyFishcakeEventManager minedAmt :",
            FishcakeEventManagerV2(address(proxyFishcakeEventManager))
                .minedAmt()
        );

        // setUp
        FishCakeCoin(address(proxyFishCakeCoin)).setRedemptionPool(
            address(redemptionPool)
        );
        IInvestorSalePool(address(proxyInvestorSalePool)).setVaultAddress(
            deployerAddress
        );

        vm.stopBroadcast();
    }
}
