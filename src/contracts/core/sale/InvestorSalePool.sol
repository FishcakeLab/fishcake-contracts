// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin-upgrades/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/utils/ReentrancyGuardUpgradeable.sol";


import "../../interfaces/IInvestorSalePool.sol";
import "./InvestorSalePoolStorage.sol";


contract InvestorSalePool is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, InvestorSalePoolStorage {
    error NotSupportFccAmount();
    error NotSupportUsdtAmount();

    error TokenUsdtAmountNotEnough();
    error FccTokenAmountNotEnough();

    event SetValutAddress(address _vaultAddress);
    event WithdrawUsdt(address indexed withdrawAddress, uint256 _amount);
    event BuyFishcakeCoin(address indexed buyer, uint256 USDTAmount, uint256 fishcakeCoinAmount);

    constructor(address _fishCakeCoin, address _redemptionPool, address _tokenUsdtAddress) InvestorSalePoolStorage(_fishCakeCoin, _redemptionPool, _tokenUsdtAddress) {
        _disableInitializers();
    }

    function initialize(address _initialOwner) public initializer {
        require(_initialOwner != address(0), "InvestorSalePool initialize: _initialOwner can't be zero address");
        __Ownable_init(_initialOwner);
        _transferOwnership(_initialOwner);
    }

    function buyFccAmount(uint256 fccAmount) external {
        if (fccAmount > fishCakeCoin.balanceOf(address(this))) {
            revert FccTokenAmountNotEnough();
        }
        uint256 tokenUsdtAmount = calculateUsdtByFcc(fccAmount);
        if (tokenUsdtAddress.balanceOf(msg.sender) < tokenUsdtAmount) {
            revert TokenUsdtAmountNotEnough();
        }
        totalSellFccAmount += fccAmount;
        totalReceiveUsdtAmount += tokenUsdtAmount;

        tokenUsdtAddress.transferFrom(msg.sender, address(this), tokenUsdtAmount / 2);
        tokenUsdtAddress.transferFrom(msg.sender, address(redemptionPool), tokenUsdtAmount / 2);

        fishCakeCoin.transfer(msg.sender, fccAmount);

        emit BuyFishcakeCoin(msg.sender, tokenUsdtAmount, fccAmount);

    }

    function buyFccByUsdtAmount(uint256 tokenUsdtAmount) external {
        if (tokenUsdtAddress.balanceOf(msg.sender) < tokenUsdtAmount) {
            revert TokenUsdtAmountNotEnough();
        }
        uint256 fccAmount = calculateFccByUsdt(tokenUsdtAmount);
        if (fccAmount > fishCakeCoin.balanceOf(address(this))) {
            revert FccTokenAmountNotEnough();
        }

        totalSellFccAmount += fccAmount;
        totalReceiveUsdtAmount += tokenUsdtAmount;

        tokenUsdtAddress.transferFrom(msg.sender, address(this), tokenUsdtAmount / 2);
        tokenUsdtAddress.transferFrom(msg.sender, address(redemptionPool), tokenUsdtAmount / 2);

        fishCakeCoin.transfer(msg.sender, fccAmount);

        emit BuyFishcakeCoin(msg.sender, tokenUsdtAmount, fccAmount);
    }

    function setValutAddress(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
        emit SetValutAddress(_vaultAddress);
    }

    function withdrawUsdt(uint256 _amount) external onlyOwner {
        tokenUsdtAddress.transfer(vaultAddress, _amount);
        emit WithdrawUsdt(vaultAddress, _amount);
    }

    function calculateFccByUsdtExternal(uint256 _amount) external pure returns (uint256) {
        return calculateFccByUsdt(_amount);
    }

    function calculateFccByUsdt(uint256 _amount) internal pure returns (uint256) {
        if (_amount >= 100_000 * usdtDecimal) { // 1 USDT = 50 FCC
            return (_amount * 50 * fccDecimal) / usdtDecimal;
        } else if (_amount < 100_000 * usdtDecimal && _amount >= 10_000 * usdtDecimal) { // 1 USDT = 25 FCC
            return (_amount * 25 * fccDecimal) / usdtDecimal;
        } else if (_amount < 10_000 * usdtDecimal && _amount >= 5_000 * usdtDecimal) { // 1 USDT = 20 FCC
            return (_amount * 20 * fccDecimal) / usdtDecimal;
        } else if (_amount < 5_000 * usdtDecimal && _amount >= 1_000 * usdtDecimal) { // 1 USDT = 16.66... FCC
            return (_amount * 100 * fccDecimal) / (6 * usdtDecimal);
        } else {
            revert NotSupportUsdtAmount();
        }
    }

    function calculateUsdtByFccExternal(uint256 _amount) external pure returns (uint256) {
        return calculateUsdtByFcc(_amount);
    }

    function calculateUsdtByFcc(uint256 _amount) internal pure returns (uint256) {
        if (_amount >= 5_000_000 * fccDecimal) {
            return (_amount * usdtDecimal) / (fccDecimal * 50); // 1 FCC = 0.02 USDT
        } else if (_amount < 5_000_000 * fccDecimal && _amount >= 250_000 * fccDecimal) {
            return (_amount * usdtDecimal) / (fccDecimal * 25); // 1 FCC = 0.04 USDT
        } else if (_amount < 250_000 * fccDecimal && _amount >= 100_000 * fccDecimal) {
            return (_amount * usdtDecimal) / (fccDecimal * 20); // 1 FCC = 0.05 USDT
        } else if (_amount < 100_000 * fccDecimal && _amount >= 16_666 * fccDecimal) {
            return (_amount * usdtDecimal) / (fccDecimal * 16); // 1 FCC = 0.06 USDT
        } else {
            revert NotSupportFccAmount();
        }
    }
}
