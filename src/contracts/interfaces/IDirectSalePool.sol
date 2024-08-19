// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDirectSalePool {
    function buyFccAmount(uint256 fccAmount) external;
    function buyFccByUsdtAmount(uint256 tokenUsdtAmount) external;
}
