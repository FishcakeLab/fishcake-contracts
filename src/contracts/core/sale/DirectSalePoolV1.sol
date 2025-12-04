// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin-upgrades/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/utils/ReentrancyGuardUpgradeable.sol";

import "./DirectSalePoolStorage.sol";
import "../../history/DirectSalePool.sol";

/// @custom:oz-upgrades-from DirectSalePool
contract DirectSalePoolV1 is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    DirectSalePoolStorage
{
    using SafeERC20 for IERC20;
    error TokenUsdtBalanceNotEnough();
    error FishcakeTokenNotEnough();

    event BuyFishcakeCoin(
        address indexed buyer,
        uint256 payUsdtAmount,
        uint256 fccAmount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
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
            "DirectSalePool initialize: _initialOwner can't be zero address"
        );
        __ERC20_init("FishCake", "FCC");
        __Ownable_init(_initialOwner);
        _transferOwnership(_initialOwner);
        __ReentrancyGuard_init();
        __DirectSalePoolStorage_init(
            _fishCakeCoin,
            _redemptionPool,
            _tokenUsdtAddress
        );
    }

    function buyFccAmount(uint256 fccAmount) external {
        require(
            fishCakeCoin.balanceOf(address(this)) >= fccAmount,
            "DirectSalePool buyFccAmount: fcc token is not enough"
        );
        uint256 payUsdtAmount = fccAmount / 10;
        require(
            payUsdtAmount > 0,
            "DirectSalePool buyFccAmount: payUsdtAmount is zero"
        );
        if (tokenUsdtAddress.balanceOf(msg.sender) < payUsdtAmount) {
            revert TokenUsdtBalanceNotEnough();
        }

        totalSellFccAmount += fccAmount;
        totalReceiveUsdtAmount += payUsdtAmount;

        tokenUsdtAddress.safeTransferFrom(
            msg.sender,
            address(redemptionPool),
            payUsdtAmount
        );

        fishCakeCoin.transfer(msg.sender, fccAmount);

        emit BuyFishcakeCoin(msg.sender, payUsdtAmount, fccAmount);
    }

    function buyFccByUsdtAmount(uint256 tokenUsdtAmount) external {
        require(
            tokenUsdtAddress.balanceOf(msg.sender) >= tokenUsdtAmount,
            "DirectSalePool buyFccAmount: usdt token is not enough"
        );
        uint256 sellFccAmount = tokenUsdtAmount * 10; // 1 USDT = 10 FCC
        if (sellFccAmount > fishCakeCoin.balanceOf(address(this))) {
            revert FishcakeTokenNotEnough();
        }

        totalSellFccAmount += sellFccAmount;
        totalReceiveUsdtAmount += tokenUsdtAmount;

        tokenUsdtAddress.safeTransferFrom(
            msg.sender,
            address(redemptionPool),
            tokenUsdtAmount
        );
        fishCakeCoin.transfer(msg.sender, sellFccAmount);

        emit BuyFishcakeCoin(msg.sender, tokenUsdtAmount, sellFccAmount);
    }

    function withdrawToken(
        address _tokenAddr,
        address _account,
        uint256 _value
    ) external onlyOwner nonReentrant returns (bool) {
        require(
            _tokenAddr != address(0x0),
            "NftManager withdrawToken:token address error."
        );
        require(
            IERC20(_tokenAddr).balanceOf(address(this)) >= _value,
            "NftManager withdrawToken: Balance not enough."
        );

        IERC20(_tokenAddr).transfer(_account, _value);

        return true;
    }
}
