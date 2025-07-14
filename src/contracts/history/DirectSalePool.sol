// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin-upgrades/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/utils/ReentrancyGuardUpgradeable.sol";

import "../core/sale/DirectSalePoolStorage.sol";


contract DirectSalePool is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, DirectSalePoolStorage {
    error TokenUsdtBalanceNotEnough();
    error FishcakeTokenNotEnough();

    event BuyFishcakeCoin(
        address indexed buyer,
        uint256 payUsdtAmount,
        uint256 fccAmount
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(address _initialOwner, address _fishCakeCoin, address _redemptionPool, address _tokenUsdtAddress) public initializer {
        require(_initialOwner != address(0), "DirectSalePool initialize: _initialOwner can't be zero address");
        __Ownable_init(_initialOwner);
        _transferOwnership(_initialOwner);
        __ReentrancyGuard_init();
        __DirectSalePoolStorage_init(_fishCakeCoin, _redemptionPool, _tokenUsdtAddress);
    }

    function buyFccAmount(uint256 fccAmount) external {
        require(fishCakeCoin.balanceOf(address(this)) >= fccAmount, "DirectSalePool buyFccAmount: fcc token is not enough");
        uint256 payUsdtAmount = fccAmount / 10;
        if (tokenUsdtAddress.balanceOf(msg.sender) < payUsdtAmount) {
            revert TokenUsdtBalanceNotEnough();
        }

        totalSellFccAmount += fccAmount;
        totalReceiveUsdtAmount += payUsdtAmount;

        tokenUsdtAddress.transferFrom(msg.sender, address(redemptionPool), payUsdtAmount);

        fishCakeCoin.transfer(msg.sender, fccAmount);

        emit BuyFishcakeCoin(msg.sender, payUsdtAmount, fccAmount);

    }

    function buyFccByUsdtAmount(uint256 tokenUsdtAmount) external {
        require(tokenUsdtAddress.balanceOf(msg.sender) >= tokenUsdtAmount, "DirectSalePool buyFccAmount: usdt token is not enough");
        uint256 sellFccAmount = tokenUsdtAmount * 10;  // 1 USDT = 10 FCC
        if (sellFccAmount > fishCakeCoin.balanceOf(address(this))) {
            revert FishcakeTokenNotEnough();
        }

        totalSellFccAmount += sellFccAmount;
        totalReceiveUsdtAmount += tokenUsdtAmount;

        tokenUsdtAddress.transferFrom(msg.sender, address(redemptionPool), tokenUsdtAmount);
        fishCakeCoin.transfer(msg.sender, sellFccAmount);

        emit BuyFishcakeCoin(msg.sender, tokenUsdtAmount, sellFccAmount);
    }
}
