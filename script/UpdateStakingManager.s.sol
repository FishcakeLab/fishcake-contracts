// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

// ====== 你的新逻辑合约 ======
import {StakingManager as StakingManagerImpl} from "../src/contracts/core/StakingManager.sol";

contract UpgradeStakingManagerScript is Script {
    // Proxy 地址
    address constant PROXY = 0x19C6bf3Ae8DFf14967C1639b96887E8778738417;

    function run() external {
        uint256 deployer = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployer);

        StakingManagerImpl newImpl = new StakingManagerImpl();
        console.log("New Implementation:", address(newImpl));

        UUPSUpgradeable proxy = UUPSUpgradeable(PROXY);
        proxy.upgradeToAndCall(address(newImpl), "");

        console.log("Upgrade completed!");

        // StakingManagerImpl(payable(PROXY)).setHalfAprTimeStamp(1780185600); // 2026-05-31 00:00:00

        vm.stopBroadcast();

        uint256 halfAprTimeStamp = StakingManagerImpl(payable(PROXY))
            .halfAprTimeStamp();
        console.log("halfAprTimeStamp after upgrade:", halfAprTimeStamp);
    }
}
