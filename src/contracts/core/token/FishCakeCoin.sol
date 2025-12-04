// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin-upgrades/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/utils/ReentrancyGuardUpgradeable.sol";

import "./FishCakeCoinStorage.sol";

contract FishCakeCoin is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    FishCakeCoinStorage
{
    event SetRedemptionPool(address indexed RedemptionPool);
    event SetPoolAddress(fishCakePool indexed pool);
    string private constant NAME = "Fishcake Coin";
    string private constant SYMBOL = "FCC";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyRedemptionPool() {
        require(
            msg.sender == RedemptionPool,
            "FishCakeCoin onlyRedemptionPool: Only RedemptionPool can call this function"
        );
        _;
    }

    function initialize(
        address _owner,
        address _RedemptionPool
    ) public initializer {
        require(
            _owner != address(0),
            "FishCakeCoin initialize: _owner can't be zero address"
        );
        __ERC20_init(NAME, SYMBOL);
        __ERC20Burnable_init();
        __Ownable_init(_owner);
        RedemptionPool = _RedemptionPool;
        _transferOwnership(_owner);
        __ReentrancyGuard_init();
        isAllocation = false;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function FccBalance(address _address) external view returns (uint256) {
        return balanceOf(_address);
    }

    function setRedemptionPool(address _RedemptionPool) external onlyOwner {
        RedemptionPool = _RedemptionPool;
        emit SetRedemptionPool(_RedemptionPool);
    }

    function setPoolAddress(fishCakePool memory _pool) external onlyOwner {
        _beforeAllocation();
        _beforePoolAddress(_pool);
        fcPool = _pool;
        emit SetPoolAddress(_pool);
    }

    function poolAllocate() external onlyOwner {
        _beforeAllocation();
        _mint(fcPool.miningPool, (MaxTotalSupply * 3) / 10); // 30% of total supply
        _mint(fcPool.directSalePool, (MaxTotalSupply * 2) / 10); // 20% of total supply
        _mint(fcPool.investorSalePool, MaxTotalSupply / 10); // 10% of total supply
        _mint(fcPool.nftSalesRewardsPool, (MaxTotalSupply * 2) / 10); // 20% of total supply
        _mint(fcPool.ecosystemPool, MaxTotalSupply / 10); // 10% of total supply
        _mint(fcPool.foundationPool, MaxTotalSupply / 10); // 10% of total supply
        isAllocation = true;
    }

    function burn(address user, uint256 _amount) external onlyRedemptionPool {
        _burn(user, _amount);
        _redemptionPoolBurnedTokens += _amount;
        emit Burn(_amount, totalSupply());
    }

    function FccTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    // ==================== internal function =============================
    function _beforeAllocation() internal virtual {
        require(
            !isAllocation,
            "FishCakeCoin _beforeAllocation:Fishcake is already allocate"
        );
    }

    function _beforePoolAddress(fishCakePool memory _pool) internal virtual {
        require(
            _pool.miningPool != address(0),
            "FishCakeCoin _beforeAllocation:Missing allocate MiningPool address"
        );
        require(
            _pool.directSalePool != address(0),
            "FishCakeCoin _beforeAllocation:Missing allocate DirectSalePool address"
        );
        require(
            _pool.investorSalePool != address(0),
            "FishCakeCoin _beforeAllocation:Missing allocate InvestorSalePool address"
        );
        require(
            _pool.nftSalesRewardsPool != address(0),
            "FishCakeCoin _beforeAllocation:Missing allocate NFTSalesRewardsPool address"
        );
        require(
            _pool.ecosystemPool != address(0),
            "FishCakeCoin _beforeAllocation:Missing allocate EcosystemPool address"
        );
        require(
            _pool.foundationPool != address(0),
            "FishCakeCoin _beforeAllocation:Missing allocate FoundationPool address"
        );
    }
}
