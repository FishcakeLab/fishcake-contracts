// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FishcakeCoin is ERC20, Ownable {
    uint256 public immutable MaxTotalSupply = 1_000_000_000 * 10 ** 6;
    bool MintingFinished = false;
    uint256 public _burnedTokens; 
    address public MiningPool;
    address public DirectSalePool;
    address public InvestorSalePool;
    address public NFTSalesRewardsPool;
    address public EcosystemPool;
    address public FoundationPool;
    address public RedemptionPool;

    constructor() ERC20("Fishcake Coin", "FCC") Ownable(msg.sender) {}

    modifier onlyRedemptionPool() {
        require(
            msg.sender == RedemptionPool,
            "Only RedemptionPool can call this function"
        );
        _;
    }
    function decimals() public view virtual override returns (uint8) {
        return 6; 
    }

    function setPoolAddress(
        address _MiningPool,
        address _DirectSalePool,
        address _InvestorSalePool,
        address _NFTSalesRewardsPool,
        address _EcosystemPool,
        address _FoundationPool
    ) public onlyOwner {
        MiningPool = _MiningPool;
        DirectSalePool = _DirectSalePool;
        InvestorSalePool = _InvestorSalePool;
        NFTSalesRewardsPool = _NFTSalesRewardsPool;
        EcosystemPool = _EcosystemPool;
        FoundationPool = _FoundationPool;
    }

    function setRedemptionPool(address _RedemptionPool) public onlyOwner {
        RedemptionPool = _RedemptionPool;
    }

    function PoolAllocation() public onlyOwner {
        require(MintingFinished == false, "Minting has been finished");
        require(
            MiningPool != address(0),
            "Missing allocate MiningPool address"
        );
        require(
            DirectSalePool != address(0),
            "Missing allocate DirectSalePool address"
        );
        require(
            InvestorSalePool != address(0),
            "Missing allocate InvestorSalePool address"
        );
        require(
            NFTSalesRewardsPool != address(0),
            "Missing allocate NFTSalesRewardsPool address"
        );
        require(
            EcosystemPool != address(0),
            "Missing allocate EcosystemPool address"
        );
        require(
            FoundationPool != address(0),
            "Missing allocate FoundationPool address"
        );
        _mint(MiningPool, (MaxTotalSupply * 3) / 10); // 30% of total supply
        _mint(DirectSalePool, (MaxTotalSupply * 2) / 10); // 20% of total supply
        _mint(InvestorSalePool, MaxTotalSupply / 10); // 10% of total supply
        _mint(NFTSalesRewardsPool, (MaxTotalSupply * 2) / 10); // 20% of total supply
        _mint(EcosystemPool, MaxTotalSupply / 10); // 10% of total supply
        _mint(FoundationPool, MaxTotalSupply / 10); // 10% of total supply
        MintingFinished = true;
    }

    function burn(address user, uint256 _amount) public onlyRedemptionPool {
        _burn(user, _amount);
        _burnedTokens+=_amount;
    }
}
