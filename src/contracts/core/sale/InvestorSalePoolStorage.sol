// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/IDirectSalePool.sol";
import "../../interfaces/IRedemptionPool.sol";
import "../../interfaces/IInvestorSalePool.sol";

abstract contract InvestorSalePoolStorage is IInvestorSalePool {
    using SafeERC20 for IERC20;

    uint256 public immutable usdtDecimal = 10 ** 6;
    uint256 public immutable fccDecimal = 10 ** 6;


    IERC20 public immutable fishCakeCoin;
    IRedemptionPool public immutable redemptionPool;
    IERC20 public immutable tokenUsdtAddress;

    address public vaultAddress;

    uint256 public totalSellFccAmount;
    uint256 public totalReceiveUsdtAmount;

    constructor(address _fishCakeCoin, address _redemptionPool, address _tokenUsdtAddress) {
        fishCakeCoin = IERC20(_fishCakeCoin);
        redemptionPool = IRedemptionPool(_redemptionPool);
        tokenUsdtAddress = IERC20(_tokenUsdtAddress);
        totalSellFccAmount = 0;
        totalReceiveUsdtAmount = 0;
    }

    uint256[100] private __gap;
}
