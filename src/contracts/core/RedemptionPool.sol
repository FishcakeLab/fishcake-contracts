// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./token/FishcakeCoin.sol";

contract RedemptionPool is ReentrancyGuard {
    using SafeERC20 for IERC20;
    error USDTAmountIsZero();
    error NotEnoughUSDT();
    event ClaimSuccess(
        address indexed user,
        uint256 USDTAmount,
        uint256 fishcakeCoinAmount
    );

    FishcakeCoin public fishcakeCoin;

   //IERC20 public immutable USDT =IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IERC20 public immutable USDT;

    uint public immutable TwoYears = 730 days;
    //uint256 public immutable OneUSDT = 10 ** 6;
    //uint256 public immutable OneFCC = 10 ** 6;
    uint256 public UnlockTime;

    modifier IsUnlock() {
        require(block.timestamp > UnlockTime, "Redemption is locked");
        _;
    }

    constructor(address _fishcakeCoin,address _USDT) {
        fishcakeCoin = FishcakeCoin(_fishcakeCoin);
        UnlockTime = block.timestamp + TwoYears;
        USDT = IERC20(_USDT);
    }

    function claim(uint256 _amount) public IsUnlock nonReentrant {        
        uint USDTAmount = calculateUSDT(_amount);
        fishcakeCoin.burn(msg.sender, _amount);
        if (USDTAmount == 0) {
            revert USDTAmountIsZero();
        }
        if (USDTAmount > balance()) {
            revert NotEnoughUSDT();
        }
        USDT.safeTransfer(msg.sender, USDTAmount);

        emit ClaimSuccess(msg.sender, USDTAmount, _amount);
    }

    function balance() public view returns (uint256) {
        return USDT.balanceOf(address(this));
    }

    function calculateUSDT(uint256 _amount) public view returns (uint256) {
        // USDT balance / fishcakeCoin total supply
        return balance() * _amount  / fishcakeCoin.totalSupply();

            
    }
}
