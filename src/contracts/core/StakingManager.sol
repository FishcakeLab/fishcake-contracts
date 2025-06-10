// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/utils/ReentrancyGuardUpgradeable.sol";

import { StakingManagerStorage } from "./StakingManagerStorage.sol";


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

        (stakingTimestamp, _ ) = getStakingPeriodAndApr(stakingType);
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

    function withdrawFromStakingWithAprIncome(uint256 amount, uint256 messageNonce, uint8 stakingType) external nonReentrant {
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

        uint256 rewardAprFunding = calculateArpFunding(msg.sender, stakingQueued[msg.sender][txMessageHash].amount, stakingQueued[msg.sender][txMessageHash].stakingType);

        IERC20(fccAddress).safeTransfer(msg.sender, amount);
        IERC20(fccAddress).safeTransfer(msg.sender, rewardAprFunding);

        emit StakeHolderWithdrawStaking(msg.sender, amount, messageNonce, txMessageHash);
    }


    //==========================internal function===============================
    function calculateArpFunding(address miner, uint256 stakingAmount, uint256 stakingType) internal pure returns(uint256) {
        uint256 nftApr =getNftApr(miner);
        uint256 stakingArp = 0;
        ( _,  stakingArp) = getStakingPeriodAndApr(stakingType);
        uint256 totalRewardApr = nftApr + stakingArp;
        if (block.timestamp - startStakingTime >= lockOneYears) {
            return stakingAmount * totalRewardApr / 100 / 2;
        }
        return stakingAmount * totalRewardApr / 100;
    }

    function getNftApr(address miner) internal view returns(uint256) {
        uint8 nftType = nftManagerAddress.getActiveMinerBoosterNftType(miner);
        if (nftType == 6) {
            return 20;
        } else if (nftType == 5) {
            return 15;
        } else if (nftType == 4) {
            return 9;
        } else if (nftType == 3) {
            return 5;
        }  else {
            return 0;
        }
    }


    function getStakingPeriodAndApr(uint8 stakingType) internal view returns(uint256, uint256) {
        require(stakingType > 0 && stakingType < 6, "StakingManager getStakingPeriod: stakingType amount must be more than 0 and less than 4");
        if (stakingType == 1) {
            return (lockThirtyDays, 25);
        } else if (stakingType == 2) {
            return (lockSixtyDays, 99);
        } else if (stakingType == 3) {
            return (lockNinetyDays, 222);
        } else if (stakingType==4) {
            return (lockHalfYears, 740);
        } else {
            return lockOneYears;
        }
    }
}
