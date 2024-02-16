// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../test/mocks/EmptyContract.sol";

import "forge-std/Script.sol";


// forge script script/Deployer.s.sol:TreasureDeployer --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast -vvvv
contract PrivacyContractsDeployer is Script {
    ProxyAdmin public savourTsProxyAdmin;
    EmptyContract public emptyContract;
    address[] pausers;

    function run() external {
        vm.startBroadcast();
        // todo: write deploy script here
        vm.stopBroadcast();
    }
}
