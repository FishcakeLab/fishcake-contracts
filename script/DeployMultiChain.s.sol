// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "openzeppelin-foundry-upgrades/Upgrades.sol";
import {FishcakeEventManagerMultiChain} from "../src/contracts/core/FishcakeEventManagerMultiChain.sol";

contract DeployMultiChain is Script {
    // USDT addresses on different chains
    address constant BSC_USDT = 0x55d398326f99059fF775485246999027B3197955;
    address constant POLYGON_USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address constant ARBITRUM_USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant OPTIMISM_USDT = 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58;
    address constant BASE_USDT = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant ETH_USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    // Testnet USDT addresses
    address constant BSC_TESTNET_USDT = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd;
    address constant SEPOLIA_USDT = 0x7169D38820dfd117C3FA1f22a697dBA58d90BA06;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("==== Fishcake Multi-Chain Deployment ====");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        // Get USDT address for current chain
        address usdtAddress = getUSDTAddress(block.chainid);
        require(usdtAddress != address(0), "USDT address not found for this chain");

        console.log("USDT address:", usdtAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy proxy
        address proxy = Upgrades.deployTransparentProxy(
            "FishcakeEventManagerMultiChain.sol",
            deployer,
            abi.encodeCall(
                FishcakeEventManagerMultiChain.initialize,
                (deployer, usdtAddress)
            )
        );

        console.log("\n=== Deployment Successful ===");
        console.log("Proxy Address:", proxy);
        
        // Get implementation address
        bytes32 implSlot = vm.load(proxy, bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        address implementation = address(uint160(uint256(implSlot)));
        console.log("Implementation:", implementation);

        vm.stopBroadcast();

        console.log("\n=== Next Steps ===");
        console.log("1. Verify contract:");
        console.log("   forge verify-contract", implementation, "FishcakeEventManagerMultiChain --chain-id", block.chainid);
        console.log("2. Interact with proxy at:", proxy);
    }

    function getUSDTAddress(uint256 chainId) internal pure returns (address) {
        // Mainnets
        if (chainId == 56) return BSC_USDT; // BSC
        if (chainId == 137) return POLYGON_USDT; // Polygon
        if (chainId == 42161) return ARBITRUM_USDT; // Arbitrum
        if (chainId == 10) return OPTIMISM_USDT; // Optimism
        if (chainId == 8453) return BASE_USDT; // Base
        if (chainId == 1) return ETH_USDT; // Ethereum
        
        // Testnets
        if (chainId == 97) return BSC_TESTNET_USDT; // BSC Testnet
        if (chainId == 11155111) return SEPOLIA_USDT; // Sepolia
        
        return address(0);
    }
}