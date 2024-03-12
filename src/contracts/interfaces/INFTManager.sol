// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INFTManager {
    function merchantNTFDeadline(
        address _account
    ) external view returns (uint256 _deadline);

    function userNTFDeadline(
        address _account
    ) external view returns (uint256 _deadline);
}
