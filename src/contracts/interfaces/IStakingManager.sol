// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStakingManager {
    event StakeHolderDepositStaking(
        address indexed staker,
        uint256 amount,
        uint8 stakingType,
        uint256 startStakingTime,
        uint256 endStakingTime,
        uint256 bindingNft,
        uint256 nftApr,
        bool isAutoRenew,
        uint256 messageNonce
    );

    event StakeHolderWithdrawStaking(
        address indexed recipant,
        uint256 withdrawAmount,
        uint256 messageNonce,
        bytes32 messageHash,
        uint256 rewardAprFunding
    );

    event Received(address indexed receiver, uint256 _value);

    error FundingUnderStaking(uint256 amount, uint256 endTime);
    error NoFundingForStaking();

    function depositIntoStaking(
        uint256 amount,
        uint8 stakingType,
        bool isAutonew,
        uint256 tokenId
    ) external;

    function withdrawFromStakingWithAprIncome(
        uint256 amount,
        uint256 messageNonce
    ) external;
}
