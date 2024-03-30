// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./token/FishcakeCoin.sol";

contract RedemptionPool {
    using SafeERC20 for ERC20;
    error USDTAmountIsZero();
    error NotEnoughUSDT();
    event ClaimSuccess(address indexed user, uint256 USDTAmount, uint256 fishcakeCoinAmount);

    FishcakeCoin public fishcakeCoin;

    ERC20 public USDT = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    uint public constant  TwoYears = 730 days;
    uint256 public constant OneUSDT = 10 ** 6;
    uint256 public constant OneFCC = 10 ** 18;
    uint256 public  UnlockTime;


    modifier IsUnlock() {
        require(block.timestamp > UnlockTime, "Redemption is locked");
        _;
    }


    constructor(address _fishcakeCoin) {
        fishcakeCoin = FishcakeCoin(_fishcakeCoin);
        UnlockTime = block.timestamp + TwoYears;
    }

    function claim(uint256 _amount) public IsUnlock {

        fishcakeCoin.burn(msg.sender, _amount);
        uint USDTAmount = calculateUSDT(_amount);
        if(USDTAmount == 0){
            revert USDTAmountIsZero();
        }
        if(USDTAmount > balance()){
            revert NotEnoughUSDT();
        }
        USDT.safeTransfer(msg.sender, USDTAmount);

        emit ClaimSuccess(msg.sender, USDTAmount, _amount);

    }


    function balance() public view returns(uint256){
        return USDT.balanceOf(address(this));
    }


    function calculateUSDT(uint256 _amount) public view returns(uint256){
        // USDT balance / fishcakeCoin total supply
        return balance() * _amount * OneUSDT / (OneFCC * (fishcakeCoin.totalSupply()-fishcakeCoin._burnedTokens()));
    }


}
