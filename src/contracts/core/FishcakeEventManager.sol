// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {INFTManager} from "../interfaces/INFTManager.sol";

contract FishcakeEventManager is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    //IERC20 constant public FccTokenAddr = IERC20(0x67AAFdb3aD974A6797D973F00556c603485F7158);
    IERC20 public immutable FccTokenAddr;
    IERC20 public immutable UsdtTokenAddr;
    INFTManager public iNFTManager;
    uint256 public immutable totalMineAmt = 300_000_000 * 10 ** 6; // Total mining quantity
    //30 days = 2592000 s
    uint256 private immutable maxDeadLine = 2592000;
    uint256 public minedAmt = 0; // Mined quantity
    uint8 public minePercent = 50; // Mining percentage
    bool public isMint = true; // Whether to mint
    uint256 private immutable oneDay = 86400; //one day 86400 s
    uint256 public immutable merchantOnceMaxMineAmt = 240 * 10 ** 6; // pro nft once max mining quantity
    uint256 public immutable userOnceMaxMineAmt = 24 * 10 ** 6; // basic nft once max mining quantity
    mapping(address => uint256) public NTFLastMineTime; // nft last mining time


    

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

    ActivityInfo[] public activityInfoArrs; // all

    struct ActivityInfoExt {
        uint256 activityId; // Activity ID
        uint256 alreadyDropAmts; // Total rewarded quantity
        uint256 alreadyDropNumber; // Total number of rewarded units
        uint256 businessMinedAmt; // Mining rewards obtained by the merchant
        uint256 businessMinedWithdrawedAmt; // Mining rewards already withdrawn by the merchant
        uint8 activityStatus; // Activity status: 1 indicates ongoing, 2 indicates ended
    }

    ActivityInfoExt[] public activityInfoExtArrs; // Translation: Array of all activities

    uint256[] public activityInfoChangedIdx; // Translation: Indices of changed statuses

    struct DropInfo {
        uint256 activityId; // Activity ID
        address userAccount; // Initiator's account（0x...）
        uint256 dropTime; // drop Time
        uint256 dropAmt; // drop amount
    }

    DropInfo[] public dropInfoArrs; // drop InfoA rrs

    // Activity ID => user => Whether the reward has been obtained before
    mapping(uint256 => mapping(address => bool)) public activityDropedToAccount;

    event SetMinePercent(uint8 minePercent);
    event AddMineAmt(address indexed who, uint256 _addMineAmt);
    event ActivityAdd(
        address indexed who,
        uint256 indexed _activityId,
        uint256 _totalDropAmts,
        string _businessName,
        string _activityContent,
        string _latitudeLongitude,
        uint256 _activityDeadLine,
        uint8 _dropType,
        uint256 _dropNumber,
        uint256 _minDropAmt,
        uint256 _maxDropAmt,
        address _tokenContractAddr
    );
    event ActivityFinish(
        uint256 indexed _activityId,
        address _tokenContractAddr,
        uint256 _returnAmount,
        uint256 _minedAmount
    );
    event Drop(
        address indexed who,
        uint256 indexed _activityId,
        uint256 _dropAmt
    );
   
    event SetValidTime(address indexed who, uint256 _time);

    constructor(
        address initialOwner,
        address _fccAddress,
        address _usdtTokenAddr,
        address _NFTManagerAddr
    ) Ownable(initialOwner) {
        FccTokenAddr = IERC20(_fccAddress);
        UsdtTokenAddr = IERC20(_usdtTokenAddr);

        iNFTManager = INFTManager(_NFTManagerAddr);
    }

    /*
        Add activity, anyone can contribute
        Parameters：
        _businessName Merchant name
        _activityContent Activity content
        _latitudeLongitude Latitude and longitude
        _activityDeadLine The end time of the activity, which needs to be passed as a TimeStamp to the backend (e.g. 1683685034)
        _totalDropAmts  The total reward quantity is determined by _maxDropAmt * _dropNumber and does not require user input (when calling the contract, the user's input number needs to be multiplied by 10 to the power of 6).
        _dropType     Reward rules: 1 represents average acquisition, 2 represents random.
        _dropNumber      Number of reward units
        _minDropAmt     When dropType is 1, fill in 0; when it is 2, fill in the minimum quantity to be received for each unit (when calling the contract, the user's input number needs to be multiplied by 10 to the power of 6).
        _maxDropAmt     When dropType is 1, fill in the quantity of each reward; when it is 2, fill in the maximum quantity to be received for each unit. The total reward quantity is determined by multiplying this field by the number of reward units (when calling the contract, the user's input number needs to be multiplied by 10 to the power of 6).
        _tokenContractAddr    Token Contract Address，For example, USDT contract address: 0x55d398326f99059fF775485246999027B3197955
        
        Return value：
        _ret   Was it successful?
        _activityId  Activity ID
        ps: Before calling this method in the front end, it is necessary to first call the "approve" method of FCCToken to authorize this contract address to access and use the user's wallet FCCToken.
        The specific authorization number is calculated as _maxDropAmt * 10 to the power of 6 * _dropNumber.
    */
    function activityAdd(
        string memory _businessName,
        string memory _activityContent,
        string memory _latitudeLongitude,
        uint256 _activityDeadLine,
        uint256 _totalDropAmts,
        uint8 _dropType,
        uint256 _dropNumber,
        uint256 _minDropAmt,
        uint256 _maxDropAmt,
        address _tokenContractAddr
    ) public nonReentrant returns (bool _ret, uint256 _activityId) {
        require(_dropType == 2 || _dropType == 1, "Drop Type Error.");
        require(_maxDropAmt >= _minDropAmt, "MaxDropAmt Setup Error.");
        require(_totalDropAmts > 0, "Drop Amount Error.");
        require(
            block.timestamp < _activityDeadLine &&
                _activityDeadLine < block.timestamp + maxDeadLine,
            "Activity DeadLine Error."
        );

        require(
            _totalDropAmts == _maxDropAmt * _dropNumber,
            "Drop Number Not Meet Total Drop Amounts."
        );
        require(
            _totalDropAmts >=100e6,
            "Total Drop Amounts Too Little , Minimum of100."
        );
         require(
            _dropNumber < 101 || _dropNumber < _totalDropAmts/10e6,
            "Drop Number Too Large ,Limt 100 or TotalDropAmts/10."
        );
        
        require(
            _tokenContractAddr == address(UsdtTokenAddr) ||
                _tokenContractAddr == address(FccTokenAddr),
            "Token contract address error"
        );
        if(_dropType==1){
            _minDropAmt=0;
        }

        // Transfer token to this contract for locking.
        IERC20(_tokenContractAddr).safeTransferFrom(
            _msgSender(),
            address(this),
            _totalDropAmts
        );

        ActivityInfo memory ai = ActivityInfo({
            activityId: activityInfoArrs.length + 1,
            businessAccount: _msgSender(),
            businessName: _businessName,
            activityContent: _activityContent,
            latitudeLongitude: _latitudeLongitude,
            activityCreateTime: block.timestamp,
            activityDeadLine: _activityDeadLine,
            dropType: _dropType,
            dropNumber: _dropNumber,
            minDropAmt: _minDropAmt,
            maxDropAmt: _maxDropAmt,
            tokenContractAddr: _tokenContractAddr
        });

        ActivityInfoExt memory aie = ActivityInfoExt({
            activityId: activityInfoArrs.length + 1,
            alreadyDropAmts: 0,
            alreadyDropNumber: 0,
            businessMinedAmt: 0,
            businessMinedWithdrawedAmt: 0,
            activityStatus: 1
        });
        activityInfoArrs.push(ai);
        activityInfoExtArrs.push(aie);
        emit ActivityAdd(
            _msgSender(),
            ai.activityId,
            _totalDropAmts,
            _businessName,
            _activityContent,
            _latitudeLongitude,
            _activityDeadLine,
            _dropType,
            _dropNumber,
            _minDropAmt,
            _maxDropAmt,
            _tokenContractAddr
        );
        _ret = true;
        _activityId = ai.activityId;
    }

    /*
        Merchant ends the activity.
        Parameters:
        _activityId activity ID
        return value：
        _ret  Was it successful?
    */
    function activityFinish(
        uint256 _activityId
    ) public nonReentrant returns (bool _ret) {
        ActivityInfo storage ai = activityInfoArrs[_activityId - 1];

        ActivityInfoExt storage aie = activityInfoExtArrs[_activityId - 1];

        require(ai.businessAccount == _msgSender(), "Not The Owner.");
        require(aie.activityStatus == 1, "Activity Status Error.");

        aie.activityStatus = 2;
        uint256 returnAmount = ai.maxDropAmt *
            ai.dropNumber -
            aie.alreadyDropAmts;
        uint256 minedAmount = 0;
        if (returnAmount>0) {
            IERC20(ai.tokenContractAddr).safeTransfer(
                _msgSender(),
                returnAmount
            );
        }
        //ifReward There is only one reward in 24 hours
        if (isMint && ifReward() &&
            iNFTManager.getMerchantNTFDeadline(_msgSender()) >
            block.timestamp ||
            iNFTManager.getUserNTFDeadline(_msgSender()) > block.timestamp
        ) {
            //Get the current percentage of mined tokens
            uint8 currentMinePercent = getCurrentMinePercent();
            if (minePercent != currentMinePercent) {
                minePercent = currentMinePercent;
            }
            if (
                minePercent > 0 && address(FccTokenAddr) == ai.tokenContractAddr
            ) {
                uint8 percent = (
                    iNFTManager.getMerchantNTFDeadline(_msgSender()) >
                        block.timestamp
                        ? minePercent
                        : minePercent / 2
                );
                uint256 maxMineAmtLimt = (
                    iNFTManager.getMerchantNTFDeadline(_msgSender()) >
                        block.timestamp
                        ? merchantOnceMaxMineAmt
                        : userOnceMaxMineAmt
                );
                // For each FCC release activity hosted on the platform, the activity initiator can mine tokens based on either 50% of the total token quantity consumed by the activity or 50% of the total number of participants multiplied by 20, whichever is lower.
                uint256 tmpDropedVal = aie.alreadyDropNumber * 20 * 1e6;
                uint256 tmpBusinessMinedAmt = ((
                    aie.alreadyDropAmts > tmpDropedVal
                        ? tmpDropedVal
                        : aie.alreadyDropAmts
                ) * percent) / 100; 
                if (tmpBusinessMinedAmt > maxMineAmtLimt) {
                    tmpBusinessMinedAmt = maxMineAmtLimt;
                }
                if(totalMineAmt>minedAmt){              
                    if (totalMineAmt > minedAmt + tmpBusinessMinedAmt) {
                        aie.businessMinedAmt = tmpBusinessMinedAmt;
                        minedAmt += tmpBusinessMinedAmt;
                        FccTokenAddr.safeTransfer(
                            _msgSender(),
                            tmpBusinessMinedAmt
                        );
                        minedAmount = tmpBusinessMinedAmt;
                    }else{
                        aie.businessMinedAmt = totalMineAmt - minedAmt;
                        minedAmt += aie.businessMinedAmt;
                        FccTokenAddr.safeTransfer(
                            _msgSender(),
                            aie.businessMinedAmt
                        );
                        minedAmount = aie.businessMinedAmt;
                        isMint=false;
                    }
                    NTFLastMineTime[_msgSender()] =block.timestamp;                    
                }
            }
        }

        activityInfoChangedIdx.push(_activityId - 1);

        emit ActivityFinish(
            _activityId,
            ai.tokenContractAddr,
            returnAmount,
            minedAmount
        );

        _ret = true;
    }

    /*
        Reward distribution (merchant distributing rewards to members).
        Parameters:
        _activityId  Activity Id
        _userAccount user address
        _dropAmt     Reward quantity: If the activity's dropType is random, this quantity needs to be filled in. Generating random numbers in the contract consumes a significant amount of resources; when obtaining rewards on average, this field does not need to be filled in.   // Reward rule: 1 indicates average distribution, 2 indicates random distribution
        return value：
        _ret Was it successful?
    */
    function drop(
        uint256 _activityId,
        address _userAccount,
        uint256 _dropAmt
    ) external nonReentrant returns (bool _ret) {
        require(
            activityDropedToAccount[_activityId][_userAccount] == false,
            "User Has Droped."
        );

        ActivityInfo storage ai = activityInfoArrs[_activityId - 1];
        ActivityInfoExt storage aie = activityInfoExtArrs[_activityId - 1];

        require(aie.activityStatus == 1, "Activity Status Error.");
        require(ai.businessAccount == _msgSender(), "Not The Owner.");
        require(ai.activityDeadLine>= block.timestamp, "Activity Has Expired.");

        if (ai.dropType == 2) {
            require(
                _dropAmt <= ai.maxDropAmt && _dropAmt >= ai.minDropAmt,
                "Drop Amount Error."
            );
        } else {
            _dropAmt = ai.maxDropAmt;
        }

        require(
            ai.dropNumber > aie.alreadyDropNumber,
            "Exceeded the number of rewards."
        );
        require(
            ai.maxDropAmt * ai.dropNumber >= _dropAmt + aie.alreadyDropAmts,
            "The reward amount has been exceeded."
        );

        IERC20(ai.tokenContractAddr).safeTransfer(_userAccount, _dropAmt);

        activityDropedToAccount[_activityId][_userAccount] = true;

        DropInfo memory di = DropInfo({
            activityId: _activityId,
            userAccount: _userAccount,
            dropTime: block.timestamp,
            dropAmt: _dropAmt
        });
        dropInfoArrs.push(di);

        aie.alreadyDropAmts += _dropAmt;
        aie.alreadyDropNumber++;

        //activityInfoChangedIdx.push(_activityId - 1);
        emit Drop(_userAccount, _activityId, _dropAmt);
        _ret = true;
    }



    /*
    Mined_FCC≤30M  -- Pro.currentMiningPercentage = 50%
    30M<  Mined_FCC≤100M  -- Pro.currentMiningPercentage = 40%
    100M<  Mined_FCC≤200M  -- Pro.currentMiningPercentage = 20%
    200M< Mined_FCC≤300M  -- Pro.currentMiningPercentage = 10%
    */
    function getCurrentMinePercent()
        public
        view
        returns (uint8 currentMinePercent)
    {
        if (minedAmt < 30_000_000 * 1e6) {
            currentMinePercent = 50;
        } else if (minedAmt < 100_000_000 * 1e6) {
            currentMinePercent = 40;
        } else if (minedAmt < 200_000_000 * 1e6) {
            currentMinePercent = 20;
        } else if (minedAmt < 300_000_000 * 1e6) {
            currentMinePercent = 10;
        } else {
            currentMinePercent = 0;
        }
    }

/*
There is only one reward in 24 hours
*/
    function ifReward()
        public
        view
        returns (bool _ret)
    {
        if (NTFLastMineTime[_msgSender()] == 0) {
            _ret=true;
        } else if (NTFLastMineTime[_msgSender()]-oneDay>= 0) {
           _ret=true;
        } else {
           _ret=false;
        }
        
    }
}
