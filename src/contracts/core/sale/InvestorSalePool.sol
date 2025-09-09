// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin-upgrades/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/utils/ReentrancyGuardUpgradeable.sol";

import "../../interfaces/IInvestorSalePool.sol";
import "./InvestorSalePoolStorage.sol";

contract InvestorSalePool is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    InvestorSalePoolStorage
{
    using SafeERC20 for IERC20;

    error NotSupportFccAmount();
    error NotSupportUsdtAmount();

    error TokenUsdtAmountNotEnough();
    error FccTokenAmountNotEnough();

    event SetVaultAddress(address _vaultAddress);
    event WithdrawUsdt(address indexed withdrawAddress, uint256 _amount);
    event BuyFishcakeCoin(
        address indexed buyer,
        uint256 USDTAmount,
        uint256 fishcakeCoinAmount
    );
    event WithdrawFcc(address indexed withdrawAddress, uint256 _amount);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _initialOwner,
        address _fishCakeCoin,
        address _redemptionPool,
        address _tokenUsdtAddress
    ) public initializer {
        require(
            _initialOwner != address(0),
            "InvestorSalePool initialize: _initialOwner can't be zero address"
        );
        __Ownable_init(_initialOwner);
        _transferOwnership(_initialOwner);
        __ReentrancyGuard_init();
        __InvestorSalePoolStorage_init(
            _fishCakeCoin,
            _redemptionPool,
            _tokenUsdtAddress
        );
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

        tokenUsdtAddress.safeTransferFrom(
            msg.sender,
            address(this),
            tokenUsdtAmount / 2
        );
        tokenUsdtAddress.safeTransferFrom(
            msg.sender,
            address(redemptionPool),
            tokenUsdtAmount / 2
        );

        fishCakeCoin.transfer(msg.sender, fccAmount);

        emit BuyFishcakeCoin(msg.sender, tokenUsdtAmount, fccAmount);
    }

    function buyFccByUsdtAmount(uint256 tokenUsdtAmount) external {
        require(
            tx.origin == msg.sender && msg.sender.code.length == 0,
            "only EOA"
        );

        if (tokenUsdtAddress.balanceOf(msg.sender) < tokenUsdtAmount) {
            revert TokenUsdtAmountNotEnough();
        }
        uint256 fccAmount = calculateFccByUsdt(tokenUsdtAmount);
        if (fccAmount > fishCakeCoin.balanceOf(address(this))) {
            revert FccTokenAmountNotEnough();
        }

        totalSellFccAmount += fccAmount;
        totalReceiveUsdtAmount += tokenUsdtAmount;

        tokenUsdtAddress.safeTransferFrom(
            msg.sender,
            address(this),
            tokenUsdtAmount / 2
        );
        tokenUsdtAddress.safeTransferFrom(
            msg.sender,
            address(redemptionPool),
            tokenUsdtAmount / 2
        );

        fishCakeCoin.transfer(msg.sender, fccAmount);

        emit BuyFishcakeCoin(msg.sender, tokenUsdtAmount, fccAmount);
    }

    function setVaultAddress(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
        emit SetVaultAddress(_vaultAddress);
    }

    function withdrawUsdt(uint256 _amount) external onlyOwner {
        tokenUsdtAddress.transfer(vaultAddress, _amount);
        emit WithdrawUsdt(vaultAddress, _amount);
    }

    function withdrawFcc(uint256 _amount) external onlyOwner nonReentrant {
        require(
            fishCakeCoin.balanceOf(address(this)) >= _amount,
            "Insufficient FCC balance"
        );
        fishCakeCoin.transfer(vaultAddress, _amount);
        emit WithdrawFcc(vaultAddress, _amount);
    }

    function calculateFccByUsdtExternal(
        uint256 _amount
    ) external pure returns (uint256) {
        return calculateFccByUsdt(_amount);
    }

    function calculateFccByUsdt(
        uint256 _usdtAmount
    ) internal pure returns (uint256) {
        if (_usdtAmount >= 100_000 * usdtDecimal) {
            // Tier 1: 1 FCC = 0.06 USDT
            return (_usdtAmount * 100 * fccDecimal) / (6 * usdtDecimal);
        } else if (
            _usdtAmount < 100_000 * usdtDecimal &&
            _usdtAmount >= 10_000 * usdtDecimal
        ) {
            // Tier 2: 1 FCC = 0.07 USDT
            return (_usdtAmount * 100 * fccDecimal) / (7 * usdtDecimal);
        } else if (
            _usdtAmount < 10_000 * usdtDecimal &&
            _usdtAmount >= 5_000 * usdtDecimal
        ) {
            // Tier 3: 1 FCC = 0.08 USDT
            return (_usdtAmount * 100 * fccDecimal) / (8 * usdtDecimal);
        } else if (
            _usdtAmount < 5_000 * usdtDecimal &&
            _usdtAmount >= 1_000 * usdtDecimal
        ) {
            // Tier 4: 1 FCC = 0.09 USDT
            return (_usdtAmount * 100 * fccDecimal) / (9 * usdtDecimal);
        } else if (
            _usdtAmount < 1_000 * usdtDecimal && _usdtAmount > 0 * usdtDecimal
        ) {
            // Tier 5: 1 FCC = 0.1 USDT
            return (_usdtAmount * 10 * fccDecimal) / usdtDecimal;
        } else {
            revert NotSupportUsdtAmount();
        }
    }

    function calculateUsdtByFccExternal(
        uint256 _amount
    ) external pure returns (uint256) {
        return calculateUsdtByFcc(_amount);
    }

    function calculateUsdtByFcc(
        uint256 _fccAmount
    ) internal pure returns (uint256) {
        if (_fccAmount >= 5_000_000 * fccDecimal) {
            // tier1: 1 FCC = 0.06 USDT
            return (_fccAmount * 6 * usdtDecimal) / (100 * fccDecimal);
        } else if (
            _fccAmount < 5_000_000 * fccDecimal &&
            _fccAmount >= 250_000 * fccDecimal
        ) {
            // tier2: 1 FCC = 0.07 USDT
            return (_fccAmount * 7 * usdtDecimal) / (100 * fccDecimal);
        } else if (
            _fccAmount < 250_000 * fccDecimal &&
            _fccAmount >= 100_000 * fccDecimal
        ) {
            // tier3: 1 FCC = 0.08 USDT
            return (_fccAmount * 8 * usdtDecimal) / (100 * fccDecimal);
        } else if (
            _fccAmount < 100_000 * fccDecimal &&
            _fccAmount >= 16_666 * fccDecimal
        ) {
            // tier4: 1 FCC = 0.09 USDT
            return (_fccAmount * 9 * usdtDecimal) / (100 * fccDecimal);
        } else if (
            _fccAmount < 16_666 * fccDecimal && _fccAmount > 0 * fccDecimal
        ) {
            // tier5: 1 FCC = 0.1 USDT
            return (_fccAmount * 10 * usdtDecimal) / (100 * fccDecimal);
        } else {
            revert NotSupportFccAmount();
        }
    }
}
