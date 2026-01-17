// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";

import "../../interfaces/IRedemptionPool.sol";
import "../../interfaces/IFishcakeEventManager.sol";
import "../../interfaces/INftManager.sol";
import "../../interfaces/IStakingManager.sol";

abstract contract NftManagerStorage is Initializable, INftManager {
    using Strings for uint256;
    using Strings for uint8;
    using SafeERC20 for IERC20;

    uint256 public _nextTokenId;
    // don't use 20241016 1630
    string public uriPrefix;
    uint256 public merchantValue;
    uint256 public userValue;

    //30 days = 2592000 s
    uint256 public constant validTime = 2592000;
    uint256 public constant totalMineAmt = 200_000_000 * 10 ** 6;
    uint256 public constant proMineAmt = 1000 * 10 ** 6;
    uint256 public constant basicMineAmt = 100 * 10 ** 6;
    IRedemptionPool public redemptionPoolAddress;

    uint256 public minedAmt;
    IERC20 public fccTokenAddr;
    IERC20 public tokenUsdtAddr;
    mapping(address => uint256) public merchantNftDeadline;
    mapping(address => uint256) public userNftDeadline;

    //nftTokenID => 1 merchant,2 user ==》 1 pro,2 basic
    mapping(uint256 => uint8) public nftMintType;

    string public basicNftJson;
    string public proNftJson;

    string public _customName;
    string public _customSymbol;

    string public uncommonFishcakeNftJson;
    string public rareShrimpNftJson;
    string public epicSalmonNftJson;
    string public legendaryTunaNftJson;

    IFishcakeEventManager public feManagerAddress;

    mapping(address => uint256) public minerActiveNft;

    mapping(address => uint256[]) public minerHistoryBoosterNft;

    address public boosterAddress;

    IStakingManager public stakingManagerAddress;

    // Add Used NFT metadata URIs
    string public uncommonFishcakeNftJson_Used;
    string public rareShrimpNftJson_Used;
    string public epicSalmonNftJson_Used;
    string public legendaryTunaNftJson_Used;

    // Add NFT owner mapping
    mapping(uint256 => address) public nftOwner;

    function __NftManagerStorage_init(
        address _fccTokenAddr,
        address _tokenUsdtAddr,
        address _redemptionPoolAddress
    ) internal initializer {
        fccTokenAddr = IERC20(_fccTokenAddr);
        tokenUsdtAddr = IERC20(_tokenUsdtAddr);
        redemptionPoolAddress = IRedemptionPool(_redemptionPoolAddress);

        _nextTokenId = 1;
        merchantValue = 8e7;
        userValue = 8e6;
        minedAmt = 0;

        proNftJson = "https://www.fishcake.org/image/1.json";
        basicNftJson = "https://www.fishcake.org/image/2.json";
    }
}
