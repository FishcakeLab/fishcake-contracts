// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRedemptionPool {
    function claim(uint256 _amount) external;
}
