// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IRedemptionPool.sol";
import "./token/FishCakeCoin.sol";


contract RedemptionPool is ReentrancyGuard, IRedemptionPool {
    using SafeERC20 for IERC20;

    IERC20 public immutable fishcakeCoin;
    IERC20 public immutable usdtToken;
    uint256 public immutable unlockTime = block.timestamp + 1095 days;

    error USDTAmountIsZero();
    error NotEnoughUSDT();

    event ClaimSuccess(
        address indexed user,
        uint256 tokenUsdtAmount,
        uint256 fishcakeCoinAmount
    );

    constructor(address _fishcakeCoin, address _usdtToken) {
        fishcakeCoin = IERC20(_fishcakeCoin);
        usdtToken = IERC20(_usdtToken);
    }

    function claim(uint256 _amount) external {
        require(block.timestamp > unlockTime, "RedemptionPool claim: redemption is locked");
        require(fishcakeCoin.balanceOf(msg.sender) >= _amount, "RedemptionPool claim: fcc balance is not enough");
        uint usdtAmount = calculateUsdt(_amount);
        if (usdtAmount == 0) {
            revert USDTAmountIsZero();
        }
        if (usdtAmount > balance()) {
            revert NotEnoughUSDT();
        }
        FishCakeCoin(address(fishcakeCoin)).burn(msg.sender, _amount);
        usdtToken.safeTransfer(msg.sender, usdtAmount);
        emit ClaimSuccess(msg.sender, usdtAmount, _amount);
    }

    // ==================== internal function =============================
    function balance() internal view returns (uint256) {
        return usdtToken.balanceOf(address(this));
    }

    function calculateUsdt(uint256 _amount) internal view returns (uint256){
        return usdtToken.balanceOf(address(this)) * _amount / fishcakeCoin.totalSupply();
    }
}
