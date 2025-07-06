// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStakingManager {
    event StakeHolderDepositStaking(
        address indexed staker,
        uint256 stakingAmount,
        uint256 messageNonce
    );

    event StakeHolderWithdrawStaking(
        address indexed recipant,
        uint256 withdrawAmount,
        uint256 messageNonce,
        bytes32 messageHash
    );

    event Received(address indexed receiver, uint256 _value);


    error FundingUnderStaking(uint256 amount, uint256 endTime);
    error NoFundingForStaking();

    function DepositIntoStaking(uint256 amount, uint8 stakingType) external;
    function withdrawFromStakingWithAprIncome(uint256 amount, uint256 messageNonce) external;
}
