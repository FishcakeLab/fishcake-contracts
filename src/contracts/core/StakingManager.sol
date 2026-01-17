// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/utils/ReentrancyGuardUpgradeable.sol";

import {StakingManagerStorage} from "./StakingManagerStorage.sol";
import "../interfaces/IFishcakeEventManager.sol";
import "../interfaces/INftManager.sol";

import "@openzeppelin-upgrades/contracts/proxy/utils/UUPSUpgradeable.sol";

contract StakingManager is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    StakingManagerStorage,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function initialize(
        address _initialOwner,
        address _fccAddress,
        IFishcakeEventManager _feManagerAddress,
        INftManager _nftManagerAddress
    ) public initializer {
        require(
            _initialOwner != address(0),
            "StakingManager initialize: _initialOwner can't be zero address"
        );
        feManagerAddress = _feManagerAddress;
        nftManagerAddress = _nftManagerAddress;
        fccAddress = _fccAddress;
        __Ownable_init(_initialOwner);
        _transferOwnership(_initialOwner);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        messageNonce = 0;
    }

    function depositIntoStaking(
        uint256 amount,
        uint8 stakingType,
        bool isAutoRenew,
        uint256 tokenId
    ) external nonReentrant {
        require(
            amount >= minStakeAmount,
            "StakingManager DepositIntoStaking: staking amount must be at least minStakeAmount"
        );

        IERC20(fccAddress).safeTransferFrom(msg.sender, address(this), amount);

        bytes32 txMessageHash = keccak256(
            abi.encode(msg.sender, fccAddress, amount, messageNonce)
        );

        uint256 stakingTimestamp = 0;
        uint256 apr = 0;
        (stakingTimestamp, apr) = getStakingPeriodAndApr(stakingType);
        uint endTime = block.timestamp + stakingTimestamp;

        // uint256 tokenId = nftManagerAddress.getActiveMinerBoosterNft(
        //     msg.sender
        // );
        uint256 nftApr = getNftApr(msg.sender, tokenId);

        stakeHolderStakingInfo memory ssInfo = stakeHolderStakingInfo({
            startStakingTime: block.timestamp,
            amount: amount,
            messageNonce: messageNonce,
            endStakingTime: endTime,
            stakingStatus: 0, // under staking now
            stakingType: stakingType,
            bindingNft: tokenId,
            isAutoRenew: isAutoRenew
        });

        nftManagerAddress.inActiveMinerBoosterNft(msg.sender, tokenId);

        stakingQueued[msg.sender][txMessageHash] = ssInfo;

        totalStakingAmount += amount;

        emit StakeHolderDepositStaking(
            msg.sender,
            amount,
            stakingType,
            block.timestamp,
            endTime,
            tokenId,
            nftApr,
            isAutoRenew,
            messageNonce
        );

        messageNonce++;
    }

    function withdrawFromStakingWithAprIncome(
        uint256 amount,
        uint256 messageNonce
    ) external nonReentrant {
        bytes32 txMessageHash = keccak256(
            abi.encode(msg.sender, fccAddress, amount, messageNonce)
        );
        uint256 txLockEndTime = stakingQueued[msg.sender][txMessageHash]
            .endStakingTime;
        if (block.timestamp < txLockEndTime) {
            revert FundingUnderStaking(amount, txLockEndTime);
        }
        require(
            stakingQueued[msg.sender][txMessageHash].stakingStatus == 0,
            "already withdrawn"
        );
        // uint256 amountOut = stakingQueued[msg.sender][txMessageHash].amount;
        // // if (amountOut < minStakeAmount) {
        // //     revert NoFundingForStaking();
        // // }
        totalStakingAmount -= amount;
        stakingQueued[msg.sender][txMessageHash].stakingStatus = 1; //staking end

        uint256 rewardAprFunding = calculateAprFunding(
            msg.sender,
            stakingQueued[msg.sender][txMessageHash].amount,
            stakingQueued[msg.sender][txMessageHash].stakingType,
            stakingQueued[msg.sender][txMessageHash].startStakingTime,
            stakingQueued[msg.sender][txMessageHash].bindingNft,
            stakingQueued[msg.sender][txMessageHash].isAutoRenew
        );

        IERC20(fccAddress).safeTransfer(msg.sender, amount);
        IERC20(fccAddress).safeTransfer(msg.sender, rewardAprFunding);

        emit StakeHolderWithdrawStaking(
            msg.sender,
            amount,
            messageNonce,
            txMessageHash,
            rewardAprFunding
        );
    }

    function getStakingAprFunding(
        uint256 amount,
        uint256 messageNonce
    ) external view returns (uint256) {
        bytes32 txMessageHash = keccak256(
            abi.encode(msg.sender, fccAddress, amount, messageNonce)
        );

        uint256 rewardAprFunding = calculateAprFunding(
            msg.sender,
            stakingQueued[msg.sender][txMessageHash].amount,
            stakingQueued[msg.sender][txMessageHash].stakingType,
            stakingQueued[msg.sender][txMessageHash].startStakingTime,
            stakingQueued[msg.sender][txMessageHash].bindingNft,
            stakingQueued[msg.sender][txMessageHash].isAutoRenew
        );
        return rewardAprFunding;
    }

    function withdrawETHFromContract(
        address to,
        uint256 amount
    ) external onlyOwner {
        require(
            to != address(0),
            "StakingManager withdrawETHFromContract: to can't be zero address"
        );
        require(
            amount <= address(this).balance,
            "StakingManager withdrawETHFromContract: amount must be less than balance"
        );
        (bool success, ) = to.call{value: amount}("");
        require(
            success,
            "StakingManager withdrawETHFromContract: Withdraw failed"
        );
        emit WithdrawETHFromContract(to, amount);
    }

    //==========================internal function===============================
    function calculateAprFunding(
        address miner,
        uint256 stakingAmount,
        uint8 stakingType,
        uint256 stakingTime,
        uint256 tokenId,
        bool isAutoRenew
    ) internal view returns (uint256) {
        uint256 stakingApr = 0;
        uint256 lockTime = 0;
        uint256 nftApr = getNftApr(miner, tokenId);
        (lockTime, stakingApr) = getStakingPeriodAndApr(stakingType);
        uint256 totalRewardApr = nftApr + stakingApr;
        uint256 actualStakingDuration = block.timestamp - stakingTime;

        // First calculate effective staking duration
        if (actualStakingDuration <= lockTime || isAutoRenew) {
            actualStakingDuration = actualStakingDuration;
        } else {
            actualStakingDuration = lockTime;
        }

        // Then calculate reward: booster APR only counts for lock time, staking APR counts for all time
        uint256 reward = 0;
        if (actualStakingDuration < lockTime) {
            reward =
                (stakingAmount * totalRewardApr * actualStakingDuration) /
                (100 * 365 days);
        } else {
            uint256 baseReward = (stakingAmount * totalRewardApr * lockTime) /
                (100 * 365 days);
            uint256 extraReward = (stakingAmount *
                stakingApr *
                (actualStakingDuration - lockTime)) / (100 * 365 days);
            reward = baseReward + extraReward;
        }

        // Halve the reward if past halfAprTimeStamp(2026/01/01)
        if (block.timestamp >= halfAprTimeStamp) {
            return reward / 2;
        } else {
            return reward;
        }
    }

    function getNftApr(
        address miner,
        uint256 tokenId
    ) internal view returns (uint256) {
        // uint256 decimal = 10e6;
        uint8 nftType = nftManagerAddress.getMinerBoosterNftType(tokenId);
        if (nftType == 6) {
            return 20;
        } else if (nftType == 5) {
            return 15;
        } else if (nftType == 4) {
            return 9;
        } else if (nftType == 3) {
            return 5;
        } else if (nftType == 0) {
            return 0;
        } else {
            return 0;
        }
    }

    function getStakingPeriodAndApr(
        uint8 stakingType
    ) internal pure returns (uint256, uint256) {
        require(
            stakingType > 0 && stakingType < 5,
            "StakingManager getStakingPeriod: stakingType amount must be more than 0 and less than 5"
        );
        if (stakingType == 1) {
            return (lockThirtyDays, 3);
        } else if (stakingType == 2) {
            return (lockSixtyDays, 6);
        } else if (stakingType == 3) {
            return (lockNinetyDays, 9);
        } else {
            return (lockHalfYears, 15);
        }
    }

    function setHalfAprTimeStamp(uint256 t) public onlyOwner {
        halfAprTimeStamp = t;
    }

    /// @notice 授权升级逻辑合约的函数
    /// @dev 只允许合约owner执行
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
