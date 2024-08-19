// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interface/IDirectSalePool.sol";
import "../../interface/IRedemptionPool.sol";

abstract contract DirectSalePoolStorage is IDirectSalePool {
    using SafeERC20 for IERC20;

    IERC20 public immutable fishCakeCoin;
    IRedemptionPool public immutable redemptionPool;
    IERC20 public immutable tokenUsdtAddress;

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
