// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../token/FishcakeCoin.sol";
import "../RedemptionPool.sol";

contract InvestorSalePool is Ownable{
    enum InvestorLevel{
        One, Two, Three, Four
    }
    error NotEnoughFishcakeCoin();
    error AmountLessThanMinimum();
    error InvestorLevelError();
    event BuyFishcakeCoinSuccess(address indexed buyer, InvestorLevel level, uint256 USDTAmount, uint256 fishcakeCoinAmount);
    using SafeERC20 for ERC20;

    FishcakeCoin public fishcakeCoin;
    RedemptionPool public redemptionPool;
    address public valut;
    ERC20 public USDT = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    
    uint256 public constant OneUSDT = 10 ** 6;
    uint256 public constant OneFCC = 10 ** 18;

    constructor(address _fishcakeCoin, address _redemptionPool) Ownable(msg.sender) {
        fishcakeCoin = FishcakeCoin(_fishcakeCoin);
        redemptionPool = RedemptionPool(_redemptionPool);

    }

    function Buy(uint256 _amount) public {
        InvestorLevel level = QueryLevelWithFCC(_amount);
        uint256 USDTAmount = calculateUSDT(level, _amount);
        USDT.safeTransferFrom(msg.sender, address(this), USDTAmount);
        USDT.transfer(address(redemptionPool), USDTAmount/2);
        if(_amount > fishcakeCoin.balanceOf(address(this))){
            revert NotEnoughFishcakeCoin();
        }
        fishcakeCoin.transfer(msg.sender, _amount);
        emit BuyFishcakeCoinSuccess(msg.sender, level, USDTAmount, _amount);
    }

    function BuyWithUSDT(uint256 _amount) public {

        InvestorLevel level = QueryLevelWithUSDT(_amount);
        uint256 fishcakeCoinAmount = calculateFCC(level, _amount);
        if(fishcakeCoinAmount > fishcakeCoin.balanceOf(address(this))){
            revert NotEnoughFishcakeCoin();
        }
        USDT.safeTransferFrom(msg.sender, address(this), _amount);
        USDT.transfer(address(redemptionPool), _amount/2);
        fishcakeCoin.transfer(msg.sender, fishcakeCoinAmount);
        emit BuyFishcakeCoinSuccess(msg.sender, level, _amount, fishcakeCoinAmount);
    }


    function QueryLevelWithUSDT(uint256 _amount) public view returns(InvestorLevel) {
        if(_amount >= 100_000  * OneUSDT) {
            return InvestorLevel.One;
        } else if( _amount < 100_000 * OneUSDT && _amount >= 10_000 * OneUSDT) {
            return InvestorLevel.Two;
        } else if(_amount < 10_000 * OneUSDT && _amount >= 5_000 * OneUSDT){
            return InvestorLevel.Three;
        } else if(_amount < 5_000 * OneUSDT && _amount >= 1_000 * OneUSDT){
            return InvestorLevel.Four;
        } else {
            revert AmountLessThanMinimum();
        }
    }


    function QueryLevelWithFCC(uint256 _amount) public view returns(InvestorLevel) {
        if(_amount >= 5_000_000  * OneFCC) {
            return InvestorLevel.One;
        } else if( _amount < 5_000_000 * OneFCC && _amount >= 250_000 * OneFCC) {
            return InvestorLevel.Two;
        } else if(_amount < 250_000 * OneFCC && _amount >= 100_000 * OneFCC){
            return InvestorLevel.Three;
        } else if(_amount < 100_000 * OneFCC && _amount >= 16_666 * OneFCC){
            return InvestorLevel.Four;
        } else {
            revert AmountLessThanMinimum();
        }
    }

    function calculateFCC(InvestorLevel level, uint256 _amount) public view returns(uint256) {
        if(level == InvestorLevel.One) {
            return _amount * 50 * OneFCC / OneUSDT; // 1 USDT = 50 FCC
        } else if(level == InvestorLevel.Two) {
            return _amount * 25 * OneFCC / OneUSDT; // 1 USDT = 25 FCC
        } else if(level == InvestorLevel.Three) {
            return _amount * 20 * OneFCC / OneUSDT; // 1 USDT = 20 FCC
        } else if(level == InvestorLevel.Four) {
            return _amount * 100  * OneFCC /  (6 * OneUSDT); // 1 USDT = 16.66... FCC
        } else {
            revert InvestorLevelError();
        }
    }

    function calculateUSDT(InvestorLevel level, uint256 _amount ) public view returns(uint256) {
        if(level == InvestorLevel.One) {
            return _amount  * OneUSDT / (OneFCC * 50); // 1 FCC = 0.02 USDT
        } else if(level == InvestorLevel.Two) {
            return _amount  * OneUSDT / (OneFCC * 25); // 1 FCC = 0.04 USDT
        } else if(level == InvestorLevel.Three) {
            return _amount  * OneUSDT / (OneFCC * 20); // 1 FCC = 0.05 USDT
        } else if(level == InvestorLevel.Four) {
            return _amount  * OneUSDT  * 6 / (OneFCC * 100); // 1 FCC = 0.06 USDT
        } else {
            revert InvestorLevelError();
        }
    }

    function setValut(address _valut) public onlyOwner {
        valut = _valut;
    }

    function withdrawUSDT(uint256 _amount) public onlyOwner {
        USDT.safeTransfer(valut, _amount);
    }

}
