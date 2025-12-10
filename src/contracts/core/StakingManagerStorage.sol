// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";

import "../interfaces/IFishcakeEventManager.sol";
import "../interfaces/INftManager.sol";
import "../interfaces/IStakingManager.sol";

abstract contract StakingManagerStorage is IStakingManager {
    event WithdrawETHFromContract(address indexed to, uint256 amount);

    uint256 public constant minStakeAmount = 10 * 10 ** 6;

    uint256 public constant lockThirtyDays = 30 days;

    uint256 public constant lockSixtyDays = 60 days;

    uint256 public constant lockNinetyDays = 90 days;

    uint256 public constant lockHalfYears = 180 days;

    uint256 public constant lockOneYears = 360 days;

    uint256 public halfAprTimeStamp = 1780185600; // 2026-05-31 00:00:00

    uint256 public aprOffset = 1000;

    uint256 public dayTimeStamp = 86400;

    uint256 public totalStakingAmount;

    address public fccAddress;

    uint256 public messageNonce;

    IFishcakeEventManager public feManagerAddress;

    INftManager public nftManagerAddress;

    struct stakeHolderStakingInfo {
        uint256 startStakingTime;
        uint256 amount;
        uint256 messageNonce;
        uint256 endStakingTime;
        uint8 stakingStatus;
        uint8 stakingType;
        uint256 bindingNft;
        bool isAutoRenew;
    }

    mapping(address => mapping(bytes32 => stakeHolderStakingInfo)) stakingQueued;

    uint256[100] private __gap;
}
