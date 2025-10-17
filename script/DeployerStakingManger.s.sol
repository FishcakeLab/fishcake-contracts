// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {StakingManager} from "../src/contracts/core/StakingManager.sol";
import {IFishcakeEventManager} from "../src/contracts/interfaces/IFishcakeEventManager.sol";
import {INftManager} from "../src/contracts/interfaces/INftManager.sol";

contract DeployerStakingMangerScript is Script {
    IFishcakeEventManager public constant PROXY_FISH_CAKE_EVENT_MANAGER =
        IFishcakeEventManager(
            address(0x2CAf752814f244b3778e30c27051cc6B45CB1fc9)
        );
    INftManager public constant PROXY_NFT_MANAGER =
        INftManager(address(0x2F2Cb24BaB1b6E2353EF6246a2Ea4ce50487008B));

    address public constant fccAddress =
        address(0x84eBc138F4Ab844A3050a6059763D269dC9951c6);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deploying contracts with the account:", deployerAddress);

        vm.startBroadcast(deployerPrivateKey);

        StakingManager stakingManagerImplementation = new StakingManager();

        console.log(
            "=========== StakingManager Logic address: =============",
            address(stakingManagerImplementation)
        );

        bytes memory data = abi.encodeCall(
            stakingManagerImplementation.initialize,
            (
                deployerAddress, // 升级权限和逻辑权限都在deployerAddress
                fccAddress,
                PROXY_FISH_CAKE_EVENT_MANAGER,
                PROXY_NFT_MANAGER
            )
        );

        ERC1967Proxy proxyStakingManager = new ERC1967Proxy(
            address(stakingManagerImplementation),
            data
        );

        vm.stopBroadcast();

        console.log(
            "========UUPS Proxy StakingManager Address: =========",
            address(proxyStakingManager)
        );

        console.log(
            "========StakingManager Owner: =========",
            StakingManager(payable(address(proxyStakingManager))).owner()
        );
    }
}
