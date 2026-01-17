// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgrades/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/utils/ReentrancyGuardUpgradeable.sol";

import {FishcakeEventManagerStorage} from "./FishcakeEventManagerStorage.sol";
import "../history/FishcakeEventManagerV1.sol";

/// @custom:oz-upgrades-from FishcakeEventManagerV2
contract FishcakeEventManagerV2 is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    FishcakeEventManagerStorage
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyNftManager() {
        require(
            msg.sender == address(iNFTManager) || msg.sender == owner(),
            "MessageManager: only nft manager can do this operate"
        );
        _;
    }

    function initialize(
        address _initialOwner,
        address _fccAddress,
        address _usdtTokenAddr,
        address _NFTManagerAddr
    ) public initializer {
        require(
            _initialOwner != address(0),
            "FishcakeEventManager initialize: _initialOwner can't be zero address"
        );
        __ERC20_init("FishCake", "FCC");
        __Ownable_init(_initialOwner);
        __ReentrancyGuard_init();
        __FishcakeEventManagerStorage_init(
            _fccAddress,
            _usdtTokenAddr,
            _NFTManagerAddr
        );
        _transferOwnership(_initialOwner);
    }

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
    ) public nonReentrant returns (bool, uint256) {
        require(
            _dropType == 2 || _dropType == 1,
            "FishcakeEventManager activityAdd: Drop Type Error."
        );
        require(
            _maxDropAmt >= _minDropAmt,
            "FishcakeEventManager activityAdd: MaxDropAmt Setup Error."
        );
        require(
            _totalDropAmts > 0,
            "FishcakeEventManager activityAdd: Drop Amount Error."
        );
        require(
            block.timestamp < _activityDeadLine &&
                _activityDeadLine < block.timestamp + maxDeadLine,
            "FishcakeEventManager activityAdd: Activity DeadLine Error."
        );

        require(
            _totalDropAmts == _maxDropAmt * _dropNumber,
            "FishcakeEventManager activityAdd: Drop Number Not Meet Total Drop Amounts."
        );
        require(
            _totalDropAmts >= 10e5,
            "FishcakeEventManager activityAdd: Total Drop Amounts Too Little , Minimum of 1."
        );
        require(
            _dropNumber < 101 || _dropNumber <= _totalDropAmts / 10e6,
            "FishcakeEventManager activityAdd: Drop Number Too Large ,Limit 100 or TotalDropAmts/10."
        );

        require(
            _tokenContractAddr == address(UsdtTokenAddr) ||
                _tokenContractAddr == address(FccTokenAddr),
            "FishcakeEventManager activityAdd: Token contract address error"
        );

        if (_dropType == 1) {
            _minDropAmt = 0;
        }

        // Transfer token to this contract for locking.
        IERC20(_tokenContractAddr).transferFrom(
            msg.sender,
            address(this),
            _totalDropAmts
        );

        ActivityInfo memory ai = ActivityInfo({
            activityId: activityInfoArrs.length + 1,
            businessAccount: msg.sender,
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
        return (true, ai.activityId);
    }

    function activityFinish(
        uint256 _activityId
    ) public nonReentrant returns (bool) {
        require(
            _activityId > 0 && _activityId <= activityInfoArrs.length,
            "FishcakeEventManager activityFinish: Activity Id Error."
        );
        ActivityInfo storage ai = activityInfoArrs[_activityId - 1];
        ActivityInfoExt storage aie = activityInfoExtArrs[_activityId - 1];

        require(
            ai.businessAccount == msg.sender,
            "FishcakeEventManager activityFinish: Not The Owner."
        );
        require(
            aie.activityStatus == 1,
            "FishcakeEventManager activityFinish: Activity Status Error."
        );

        aie.activityStatus = 2;
        uint256 returnAmount = ai.maxDropAmt *
            ai.dropNumber -
            aie.alreadyDropAmts;

        uint256 minedAmount = 0;
        if (returnAmount > 0) {
            IERC20(ai.tokenContractAddr).transfer(msg.sender, returnAmount);
        }

        // ifReward There is only one reward in 24 hours
        if (
            isMint &&
            ifReward() &&
            (iNFTManager.getMerchantNTFDeadline(_msgSender()) >
                block.timestamp ||
                iNFTManager.getUserNTFDeadline(_msgSender()) > block.timestamp)
        ) {
            // Get the current percentage of mined tokens
            uint8 currentMinePercent = 0;
            uint256 merchantOnceMaxMineTmpAmt = 0;
            uint256 userOnceMaxMineTmpAmt = 0;
            (
                currentMinePercent,
                merchantOnceMaxMineTmpAmt,
                userOnceMaxMineTmpAmt
            ) = getCurrentMinePercent();
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
                uint256 maxMineAmtLimit = (
                    iNFTManager.getMerchantNTFDeadline(_msgSender()) >
                        block.timestamp
                        ? merchantOnceMaxMineTmpAmt
                        : userOnceMaxMineTmpAmt
                );
                // For each FCC release activity hosted on the platform, the activity initiator can mine tokens based on either 50% of the total token quantity consumed by the activity or 50% of the total number of participants multiplied by 20, whichever is lower.
                uint256 tmpDroppedVal = aie.alreadyDropNumber * 20 * 1e6;
                uint256 tmpBusinessMinedAmt = ((
                    aie.alreadyDropAmts > tmpDroppedVal
                        ? tmpDroppedVal
                        : aie.alreadyDropAmts
                ) * percent) / 100;
                if (tmpBusinessMinedAmt > maxMineAmtLimit) {
                    tmpBusinessMinedAmt = maxMineAmtLimit;
                }
                if (totalMineAmt > minedAmt) {
                    if (totalMineAmt > minedAmt + tmpBusinessMinedAmt) {
                        aie.businessMinedAmt = tmpBusinessMinedAmt;
                        minedAmt += tmpBusinessMinedAmt;
                        FccTokenAddr.transfer(msg.sender, tmpBusinessMinedAmt);
                        minerMineAmount[msg.sender] += tmpBusinessMinedAmt;
                        minedFishcakePower[msg.sender] += tmpBusinessMinedAmt;
                        minedAmount = tmpBusinessMinedAmt;
                    } else {
                        aie.businessMinedAmt = totalMineAmt - minedAmt;
                        minedAmt += aie.businessMinedAmt;
                        FccTokenAddr.transfer(msg.sender, aie.businessMinedAmt);
                        minerMineAmount[msg.sender] += aie.businessMinedAmt;
                        minedFishcakePower[msg.sender] += aie.businessMinedAmt;
                        minedAmount = aie.businessMinedAmt;
                        isMint = false;
                    }
                    NTFLastMineTime[msg.sender] = block.timestamp;
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

        return true;
    }

    function drop(
        uint256 _activityId,
        address _userAccount,
        uint256 _dropAmt
    ) external nonReentrant returns (bool) {
        require(
            activityDroppedToAccount[_activityId][_userAccount] == false,
            "FishcakeEventManager drop: User Has Dropped."
        );

        ActivityInfo storage ai = activityInfoArrs[_activityId - 1];
        ActivityInfoExt storage aie = activityInfoExtArrs[_activityId - 1];

        require(
            aie.activityStatus == 1,
            "FishcakeEventManager drop: Activity Status Error."
        );
        require(
            ai.businessAccount == msg.sender,
            "FishcakeEventManager drop: Not The Owner."
        );
        require(
            ai.activityDeadLine >= block.timestamp,
            "FishcakeEventManager drop: Activity Has Expired."
        );

        if (ai.dropType == 2) {
            require(
                _dropAmt <= ai.maxDropAmt && _dropAmt >= ai.minDropAmt,
                "FishcakeEventManager drop: Drop Amount Error."
            );
        } else {
            _dropAmt = ai.maxDropAmt;
        }

        require(
            ai.dropNumber > aie.alreadyDropNumber,
            "FishcakeEventManager drop: Exceeded the number of rewards."
        );
        require(
            ai.maxDropAmt * ai.dropNumber >= _dropAmt + aie.alreadyDropAmts,
            "FishcakeEventManager drop: The reward amount has been exceeded."
        );

        IERC20(ai.tokenContractAddr).transfer(_userAccount, _dropAmt);

        activityDroppedToAccount[_activityId][_userAccount] = true;

        DropInfo memory di = DropInfo({
            activityId: _activityId,
            userAccount: _userAccount,
            dropTime: block.timestamp,
            dropAmt: _dropAmt
        });
        dropInfoArrs.push(di);

        aie.alreadyDropAmts += _dropAmt;
        aie.alreadyDropNumber++;

        emit Drop(_userAccount, _activityId, _dropAmt);
        return true;
    }

    function getMinerMineAmount(
        address _miner
    ) external view returns (uint256) {
        return minerMineAmount[_miner];
    }

    function deleteMinerMineAmount(address _miner) external onlyNftManager {
        delete minerMineAmount[_miner];
    }

    function getMinedFishcakePower(
        address _miner
    ) external view returns (uint256) {
        return minedFishcakePower[_miner];
    }

    function deleteMinedFishcakePower(address _miner) external onlyNftManager {
        delete minedFishcakePower[_miner];
    }

    function updateMinedFishcakePower(
        address _miner,
        uint256 _power
    ) external onlyNftManager {
        minedFishcakePower[_miner] = _power;
    }

    // ======================= internal =======================
    function getCurrentMinePercent()
        internal
        view
        returns (uint8, uint256, uint256)
    {
        uint8 currentMinePercent = 0;
        uint256 merchantOnceMaxMineTmpAmt = 0;
        uint256 userOnceMaxMineTmpAmt = 0;
        if (minedAmt < 30_000_000 * 1e6) {
            currentMinePercent = 50;
            merchantOnceMaxMineTmpAmt = 60 * 10 ** 6;
            userOnceMaxMineTmpAmt = 6 * 10 ** 6;
        } else if (minedAmt < 100_000_000 * 1e6) {
            currentMinePercent = 40;
            merchantOnceMaxMineTmpAmt = 30 * 10 ** 6;
            userOnceMaxMineTmpAmt = 3 * 10 ** 6;
        } else if (minedAmt < 200_000_000 * 1e6) {
            currentMinePercent = 20;
            merchantOnceMaxMineTmpAmt = 15 * 10 ** 6;
            userOnceMaxMineTmpAmt = 2 * 10 ** 6;
        } else if (minedAmt < 300_000_000 * 1e6) {
            currentMinePercent = 10;
            merchantOnceMaxMineTmpAmt = 8 * 10 ** 6;
            userOnceMaxMineTmpAmt = 1 * 10 ** 6;
        } else {
            currentMinePercent = 0;
            merchantOnceMaxMineTmpAmt = 0;
            userOnceMaxMineTmpAmt = 0;
        }
        return (
            currentMinePercent,
            merchantOnceMaxMineTmpAmt,
            userOnceMaxMineTmpAmt
        );
    }

    function ifReward() internal view returns (bool _ret) {
        if (NTFLastMineTime[_msgSender()] == 0) {
            _ret = true;
        } else if (block.timestamp - NTFLastMineTime[_msgSender()] >= oneDay) {
            _ret = true;
        } else {
            _ret = false;
        }
    }

    function updateMinedFishcakePowerOnlyOnce(
        address _miner
    ) external onlyOwner {
        if (minedFishcakePower[_miner] == 0) {
            minedFishcakePower[_miner] = minerMineAmount[_miner];
        }
    }
}
