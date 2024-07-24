// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/FishcakeCoin.sol";
import "../RedemptionPool.sol";

contract DirectSalePool is ReentrancyGuard {
    using SafeERC20 for IERC20;
    error NotEnoughFishcakeCoin();

    IERC20 public fishcakeCoin;
    RedemptionPool public redemptionPool;
    //IERC20 public immutable USDT =IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IERC20 public immutable USDT;

    event BuyFishcakeCoinSuccess(
        address indexed buyer,
        uint256 USDTAmount,
        uint256 fishcakeCoinAmount
    );

    constructor(address _fishcakeCoin, address _redemptionPool,address _USDT) {
        fishcakeCoin = FishcakeCoin(_fishcakeCoin);
        redemptionPool = RedemptionPool(_redemptionPool);
        USDT = IERC20(_USDT);
    }

    function Buy(uint _amount) public nonReentrant {
        uint USDTAmount = _amount  / 10; // 1FCC = 0.1 USDT
        if (_amount > fishcakeCoin.balanceOf(address(this))) {
            revert NotEnoughFishcakeCoin();
        }
        USDT.safeTransferFrom(msg.sender, address(this), USDTAmount);
        USDT.transfer(address(redemptionPool), USDTAmount);

        fishcakeCoin.transfer(msg.sender, _amount);

        emit BuyFishcakeCoinSuccess(msg.sender, USDTAmount, _amount);
    }

    function BuyWithUSDT(uint _amount) public nonReentrant {
        uint fishcakeCoinAmount = _amount * 10; // 1 USDT = 10 FCC
        if (fishcakeCoinAmount > fishcakeCoin.balanceOf(address(this))) {
            revert NotEnoughFishcakeCoin();
        }
        USDT.safeTransferFrom(msg.sender, address(this), _amount);
        USDT.transfer(address(redemptionPool), _amount);

        fishcakeCoin.transfer(msg.sender, fishcakeCoinAmount);

        emit BuyFishcakeCoinSuccess(msg.sender, _amount, fishcakeCoinAmount);
    }
}
