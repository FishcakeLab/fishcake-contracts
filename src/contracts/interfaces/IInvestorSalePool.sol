// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IInvestorSalePool {
    function buyFccAmount(uint256 fccAmount) external;
    function buyFccByUsdtAmount(uint256 tokenUsdtAmount) external;

    function setVaultAddress(address _vaultAddress) external;
    function withdrawUsdt(uint256 _amount) external;
}
