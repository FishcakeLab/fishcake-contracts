// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/IRedemptionPool.sol";
import "../../interfaces/INftManager.sol";

abstract contract NftManagerStorage is INftManager {
    using Strings for uint256;
    using Strings for uint8;
    using SafeERC20 for IERC20;

    uint256 public _nextTokenId;
    string public uriPrefix;
    uint256 public merchantValue;
    uint256 public userValue;

    //30 days = 2592000 s
    uint256 public immutable validTime = 2592000;
    uint256 public immutable totalMineAmt = 200_000_000 * 10 ** 6;
    uint256 public immutable proMineAmt = 1000 * 10 ** 6;
    uint256 public immutable basicMineAmt = 100 * 10 ** 6;
    address public redemptionPoolAddress;

    uint256 public minedAmt = 0;
    IERC20 public immutable fccTokenAddr;
    IERC20 public immutable tokenUsdtAddr;
    mapping(address => uint256) public merchantNftDeadline;
    mapping(address => uint256) public userNftDeadline;

    //nftTokenID => 1 merchant,2 user ==》 1 pro,2 basic
    mapping(uint256 => uint8) public nftMintType;


    constructor(address _fccTokenAddr, address _tokenUsdtAddr, address _redemptionPoolAddress){
        fccTokenAddr = IERC20(_fccTokenAddr);
        tokenUsdtAddr = IERC20(_tokenUsdtAddr);
        redemptionPoolAddress = _redemptionPoolAddress;
        merchantValue = 80e6;
        userValue = 8e6;
    }
}
