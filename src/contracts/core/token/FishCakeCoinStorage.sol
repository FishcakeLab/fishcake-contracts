// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


abstract contract FishCakeCoinStorage {
    uint256 public immutable MaxTotalSupply = 1_000_000_000 * 10 ** 6;

    uint256 public _burnedTokens;

    address public RedemptionPool;

    struct fishCakePool {
        address  miningPool;
        address  directSalePool;
        address  investorSalePool;
        address  nftSalesRewardsPool;
        address  ecosystemPool;
        address  foundationPool;
        address  redemptionPool;
    }

    fishCakePool public fcPool;

    event Burn(
        uint256 _burnAmount,
        uint256 _totalSupply
    );

    uint256[100] private __gap;
}
