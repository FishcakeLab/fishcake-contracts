# My Fishcake Multi-Chain Event Manager – Hackathon Project (Direction 2)

Simplified, USDT-only Event Manager contract for Fishcake (AI × Web3 Hackathon).

## What I Built
- Forked original Fishcake repo
- Removed all non-core features (FCC mining, NFT logic, complex rewards)
- Focused on **USDT stablecoin activities**
- Added upgradeability (Transparent Proxy via OpenZeppelin)
- Security: ReentrancyGuard, Pausable, SafeERC20, emergency withdraw
- Basic frontend attempt (React + wagmi + RainbowKit still building..)
- Local deployment proof with Foundry Anvil

## Requirements Met (Direction 2)
- ✅ Supports multi-chain deployment (pure EVM Solidity)
- ✅ Simplified ecological functions, core only
- ✅ USDT stablecoin-based activities
- ✅ Consistent logic across chains
- ✅ Event creation, reward distribution, verification/finish

## Tech Stack
- Solidity 0.8.26 + Foundry
- OpenZeppelin upgradeable contracts

## Future Plans
- Deploy to Sepolia + BSC Testnet when test ETH is available
- Add USDC support + token registry
- Build a full React frontend using wagmi + RainbowKit, with event listing, creation flows, and enhanced UI/UX.

Open to feedback & collaboration!
