// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INftManager {
    function getMerchantNTFDeadline(address _account) external view returns (uint256);
    function getUserNTFDeadline(address _account) external view returns (uint256);
}
