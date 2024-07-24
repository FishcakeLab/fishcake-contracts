// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../token/FishcakeCoin.sol";
import "../RedemptionPool.sol";

contract InvestorSalePool is Ownable, ReentrancyGuard {
    enum InvestorLevel {
        One,
        Two,
        Three,
        Four
    }
    error NotEnoughFishcakeCoin();
    error AmountLessThanMinimum();
    error InvestorLevelError();
    event BuyFishcakeCoinSuccess(
        address indexed buyer,
        InvestorLevel level,
        uint256 USDTAmount,
        uint256 fishcakeCoinAmount
    );
    using SafeERC20 for IERC20;

    IERC20 public fishcakeCoin;
    RedemptionPool public redemptionPool;
    address public valut;
    //IERC20 public immutable USDT =IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IERC20 public immutable USDT;

    uint256 public immutable OneUSDT = 10 ** 6;
    uint256 public immutable OneFCC = 10 ** 6;

    constructor(
        address _fishcakeCoin,
        address _redemptionPool,
        address _USDT
    ) Ownable(msg.sender) {
        fishcakeCoin = FishcakeCoin(_fishcakeCoin);
        redemptionPool = RedemptionPool(_redemptionPool);
        USDT = IERC20(_USDT);
    }

    function Buy(uint256 _amount) public nonReentrant {
        InvestorLevel level = QueryLevelWithFCC(_amount);
        uint256 USDTAmount = calculateUSDT(level, _amount);
        USDT.safeTransferFrom(msg.sender, address(this), USDTAmount);
        USDT.transfer(address(redemptionPool), USDTAmount / 2);
        if (_amount > fishcakeCoin.balanceOf(address(this))) {
            revert NotEnoughFishcakeCoin();
        }
        fishcakeCoin.transfer(msg.sender, _amount);
        emit BuyFishcakeCoinSuccess(msg.sender, level, USDTAmount, _amount);
    }

    function BuyWithUSDT(uint256 _amount) public nonReentrant {
        InvestorLevel level = QueryLevelWithUSDT(_amount);
        uint256 fishcakeCoinAmount = calculateFCC(level, _amount);
        if (fishcakeCoinAmount > fishcakeCoin.balanceOf(address(this))) {
            revert NotEnoughFishcakeCoin();
        }
        USDT.safeTransferFrom(msg.sender, address(this), _amount);
        USDT.safeTransfer(address(redemptionPool), _amount / 2);
        fishcakeCoin.safeTransfer(msg.sender, fishcakeCoinAmount);
        emit BuyFishcakeCoinSuccess(
            msg.sender,
            level,
            _amount,
            fishcakeCoinAmount
        );
    }

    function QueryLevelWithUSDT(
        uint256 _amount
    ) public pure returns (InvestorLevel) {
        if (_amount >= 100_000 * OneUSDT) {
            return InvestorLevel.One;
        } else if (_amount < 100_000 * OneUSDT && _amount >= 10_000 * OneUSDT) {
            return InvestorLevel.Two;
        } else if (_amount < 10_000 * OneUSDT && _amount >= 5_000 * OneUSDT) {
            return InvestorLevel.Three;
        } else if (_amount < 5_000 * OneUSDT && _amount >= 1_000 * OneUSDT) {
            return InvestorLevel.Four;
        } else {
            revert AmountLessThanMinimum();
        }
    }

    function QueryLevelWithFCC(
        uint256 _amount
    ) public pure returns (InvestorLevel) {
        if (_amount >= 5_000_000 * OneFCC) {
            return InvestorLevel.One;
        } else if (
            _amount < 5_000_000 * OneFCC && _amount >= 250_000 * OneFCC
        ) {
            return InvestorLevel.Two;
        } else if (_amount < 250_000 * OneFCC && _amount >= 100_000 * OneFCC) {
            return InvestorLevel.Three;
        } else if (_amount < 100_000 * OneFCC && _amount >= 16_666 * OneFCC) {
            return InvestorLevel.Four;
        } else {
            revert AmountLessThanMinimum();
        }
    }

    function calculateFCC(
        InvestorLevel level,
        uint256 _amount
    ) public pure returns (uint256) {
        if (level == InvestorLevel.One) {
            return (_amount * 50 * OneFCC) / OneUSDT; // 1 USDT = 50 FCC
        } else if (level == InvestorLevel.Two) {
            return (_amount * 25 * OneFCC) / OneUSDT; // 1 USDT = 25 FCC
        } else if (level == InvestorLevel.Three) {
            return (_amount * 20 * OneFCC) / OneUSDT; // 1 USDT = 20 FCC
        } else if (level == InvestorLevel.Four) {
            return (_amount * 100 * OneFCC) / (6 * OneUSDT); // 1 USDT = 16.66... FCC
        } else {
            revert InvestorLevelError();
        }
    }

    function calculateUSDT(
        InvestorLevel level,
        uint256 _amount
    ) public pure returns (uint256) {
        if (level == InvestorLevel.One) {
            return (_amount * OneUSDT) / (OneFCC * 50); // 1 FCC = 0.02 USDT
        } else if (level == InvestorLevel.Two) {
            return (_amount * OneUSDT) / (OneFCC * 25); // 1 FCC = 0.04 USDT
        } else if (level == InvestorLevel.Three) {
            return (_amount * OneUSDT) / (OneFCC * 20); // 1 FCC = 0.05 USDT
        } else if (level == InvestorLevel.Four) {
            return (_amount * OneUSDT * 6) / (OneFCC * 100); // 1 FCC = 0.06 USDT
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
