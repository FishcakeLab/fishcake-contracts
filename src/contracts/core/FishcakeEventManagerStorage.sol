// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";

import "../interfaces/IFishcakeEventManager.sol";
import "../interfaces/INftManager.sol";

abstract contract FishcakeEventManagerStorage is
    Initializable,
    IFishcakeEventManager
{
    using SafeERC20 for IERC20;

    uint256 public constant totalMineAmt = 300_000_000 * 10 ** 6; // Total mining quantity
    uint256 public constant maxDeadLine = 2592000; // 30 days = 2592000 s
    uint256 public constant oneDay = 86400; // one day 86400 s
    uint256 public constant merchantOnceMaxMineAmt = 240 * 10 ** 6; // pro nft once max mining quantity
    uint256 public constant userOnceMaxMineAmt = 24 * 10 ** 6; // basic nft once max mining quantity

    uint256 public minedAmt; // Mined quantity
    uint8 public minePercent; // Mining percentage
    bool public isMint; // Whether to mint

    IERC20 public FccTokenAddr;
    IERC20 public UsdtTokenAddr;
    INftManager public iNFTManager;

    struct ActivityInfo {
        uint256 activityId; // Activity ID
        address businessAccount; // Initiator's account（0x...）
        string businessName; // Merchant name
        string activityContent; // Activity content
        string latitudeLongitude; // Latitude and longitude
        uint256 activityCreateTime; // Activity creation time
        uint256 activityDeadLine; // Activity end time
        uint8 dropType; // Reward rules: 1 represents average acquisition, 2 represents random.
        uint256 dropNumber; // Number of reward units
        uint256 minDropAmt; // When dropType is 1, fill in 0; when it is 2, fill in the minimum quantity to be received for each unit.
        uint256 maxDropAmt; // When dropType is 1, fill in the quantity of each reward; when it is 2, fill in the maximum quantity to be received for each unit. The total reward quantity is determined by multiplying this field by the number of reward units.
        address tokenContractAddr; //Token Contract Address，For example, USDT contract address: 0x55d398326f99059fF775485246999027B3197955
    }

    struct ActivityInfoExt {
        uint256 activityId; // Activity ID
        uint256 alreadyDropAmts; // Total rewarded quantity
        uint256 alreadyDropNumber; // Total number of rewarded units
        uint256 businessMinedAmt; // Mining rewards obtained by the merchant
        uint256 businessMinedWithdrawedAmt; // Mining rewards already withdrawn by the merchant
        uint8 activityStatus; // Activity status: 1 indicates ongoing, 2 indicates ended
    }

    struct DropInfo {
        uint256 activityId; // Activity ID
        address userAccount; // Initiator's account（0x...）
        uint256 dropTime; // drop Time
        uint256 dropAmt; // drop amount
    }

    uint256[] public activityInfoChangedIdx; // Translation: Indices of changed statuses
    ActivityInfo[] public activityInfoArrs; // all
    ActivityInfoExt[] public activityInfoExtArrs; // Translation: Array of all activities

    DropInfo[] public dropInfoArrs; // drop InfoA rrs

    mapping(address => uint256) public NTFLastMineTime; // nft last mining time

    mapping(uint256 => mapping(address => bool))
        public activityDroppedToAccount;

    mapping(address => uint256) public minerMineAmount;

    mapping(address => uint256) public minedFishcakePower;

    function __FishcakeEventManagerStorage_init(
        address _fccAddress,
        address _usdtTokenAddr,
        address _NFTManagerAddr
    ) internal onlyInitializing {
        FccTokenAddr = IERC20(_fccAddress);
        UsdtTokenAddr = IERC20(_usdtTokenAddr);
        iNFTManager = INftManager(_NFTManagerAddr);

        minedAmt = 0;
        minePercent = 50;
        isMint = true;
    }

    uint256[98] private __gap;
}
