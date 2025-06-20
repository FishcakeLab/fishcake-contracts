// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/utils/ReentrancyGuardUpgradeable.sol";

import { StakingManagerStorage } from "./StakingManagerStorage.sol";
import "../interfaces/IFishcakeEventManager.sol";
import "../interfaces/INftManager.sol";


contract StakingManager is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, StakingManagerStorage{
    using SafeERC20 for IERC20;

    constructor(){
        _disableInitializers();
    }

    function initialize(address _initialOwner, IFishcakeEventManager _feManagerAddress, INftManager _nftManagerAddress)
        public
        initializer
    {
        require(_initialOwner != address(0), "StakingManager initialize: _initialOwner can't be zero address");
        feManagerAddress = _feManagerAddress;
        nftManagerAddress = _nftManagerAddress;
        __Ownable_init(_initialOwner);
        _transferOwnership(_initialOwner);
        __ReentrancyGuard_init();
        messageNonce = 0;
    }

    function DepositIntoStaking(uint256 amount, uint8 stakingType) external nonReentrant {
        require(amount > minStakeAmount, "StakingManager DepositIntoStaking: staking amount must be more than minStakeAmount");

        IERC20(fccAddress).safeTransfer(address(this), amount);

        bytes32 txMessageHash = keccak256(
            abi.encode(
                msg.sender,
                fccAddress,
                amount,
                messageNonce
            )
        );
        uint256 stakingTimestamp = 0;
        uint256 apr = 0;
        (stakingTimestamp, apr) = getStakingPeriodAndApr(stakingType);
        uint endTime = block.timestamp + stakingTimestamp;

        stakeHolderStakingInfo memory ssInfo = stakeHolderStakingInfo({
            startStakingTime: block.timestamp,
            amount: amount,
            messageNonce: messageNonce,
            endStakingTime: endTime,
            stakingStatus: 0, // under staking now
            stakingType: stakingType
        });

        stakingQueued[msg.sender][txMessageHash] = ssInfo;

        totalStakingAmount += amount;

        emit StakeHolderDepositStaking(msg.sender, amount, messageNonce);

        messageNonce++;
    }

    function withdrawFromStakingWithAprIncome(uint256 amount, uint256 messageNonce) external nonReentrant {
        bytes32 txMessageHash = keccak256(
            abi.encode(
                msg.sender,
                fccAddress,
                amount,
                messageNonce
            )
        );
        uint256 txLockEndTime = stakingQueued[msg.sender][txMessageHash].endStakingTime;
        if (block.timestamp < txLockEndTime) {
            revert FundingUnderStaking(
                amount,
                txLockEndTime
            );
        }
        uint256 amountOut = stakingQueued[msg.sender][txMessageHash].amount;
        if (amountOut < minStakeAmount) {
            revert NoFundingForStaking();
        }
        totalStakingAmount -= amount;
        stakingQueued[msg.sender][txMessageHash].stakingStatus = 1; //staking end

        uint256 rewardAprFunding = calculateArpFunding(
            msg.sender,
            stakingQueued[msg.sender][txMessageHash].amount,
            stakingQueued[msg.sender][txMessageHash].stakingType,
            stakingQueued[msg.sender][txMessageHash].startStakingTime
        );

        IERC20(fccAddress).safeTransfer(msg.sender, amount);
        IERC20(fccAddress).safeTransfer(msg.sender, rewardAprFunding);

        emit StakeHolderWithdrawStaking(msg.sender, amount, messageNonce, txMessageHash);
    }

    function getStakingAprFunding(uint256 amount, uint256 messageNonce)  external view returns(uint256) {
        bytes32 txMessageHash = keccak256(
            abi.encode(
                msg.sender,
                fccAddress,
                amount,
                messageNonce
            )
        );

        uint256 rewardAprFunding = calculateArpFunding(
            msg.sender,
            stakingQueued[msg.sender][txMessageHash].amount,
            stakingQueued[msg.sender][txMessageHash].stakingType,
            stakingQueued[msg.sender][txMessageHash].startStakingTime
        );
        return rewardAprFunding;
    }

    //==========================internal function===============================
    function calculateArpFunding(address miner, uint256 stakingAmount, uint8 stakingType, uint256 stakingTime) internal view returns(uint256) {
        uint256 stakingArp = 0;
        uint256 lockType = 0;
        uint256 nftApr = getNftApr(miner);
        (lockType, stakingArp) = getStakingPeriodAndApr(stakingType);
        uint256 totalRewardApr = nftApr + stakingArp;
        uint256 actualStakingDuration = block.timestamp - stakingTime;
        if (block.timestamp >= halfAprTimeStamp) {
            uint256 reward = stakingAmount * totalRewardApr * actualStakingDuration / (100 * 365 days);
            return reward / 2;
        }
        return stakingAmount * totalRewardApr * actualStakingDuration / (100 * 365 days);
    }

    function getNftApr(address miner) internal view returns(uint256) {
        uint256 decimal = 10e6;
        uint8 nftType = nftManagerAddress.getActiveMinerBoosterNftType(miner);
        uint256 minerAmount = feManagerAddress.getMinerMineAmount(miner);
        if (nftType == 6 || minerAmount >= 1600 * decimal) {
            return 20;
        } else if (nftType == 5 || (minerAmount < 1600 * decimal && minerAmount >= 1000 * decimal)) {
            return 15;
        } else if (nftType == 4 || (minerAmount < 1000 * decimal && minerAmount >= 160 * decimal)) {
            return 9;
        } else if (nftType == 3 || (minerAmount < 160 * decimal && minerAmount >= 100 * decimal)) {
            return 5;
        }  else {
            return 0;
        }
    }

    function getStakingPeriodAndApr(uint8 stakingType) internal pure returns(uint256, uint256) {
        require(stakingType > 0 && stakingType < 5, "StakingManager getStakingPeriod: stakingType amount must be more than 0 and less than 4");
        if (stakingType == 1) {
            return (lockThirtyDays, 25);
        } else if (stakingType == 2) {
            return (lockSixtyDays, 99);
        } else if (stakingType == 3) {
            return (lockNinetyDays, 222);
        } else {
            return (lockHalfYears, 740);
        }
    }
}
