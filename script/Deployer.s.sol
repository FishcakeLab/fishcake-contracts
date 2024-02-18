// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {MerchantManger} from "../src/contracts/core/MerchantManger.sol";
import {FccToken} from "../src/contracts/core/FccToken.sol";

import "forge-std/Script.sol";

import "./BaseScript.sol";


// forge script script/Deployer.s.sol:TreasureDeployer --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast -vvvv
//forge script script/Deployer.s.sol:PrivacyContractsDeployer --rpc-url $MUMBAI_RPC_URL --broadcast -vvvv
contract PrivacyContractsDeployer is BaseScript {
   

    function run() external  broadcaster{
        
        // todo: write deploy script here        
        FccToken fct = new FccToken(deployer);
        fct.mint(deployer, 1000000000e18);
        console.log("The Deployer address:", deployer);
        console.log("FccToken deployed on %s", address(fct));
        MerchantManger merchantManger = new MerchantManger();
        merchantManger.initialize(address(fct));       
        console.log("MerchantManger deployed on %s", address(merchantManger));
        
    }
}
