// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin-upgrades/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/utils/ReentrancyGuardUpgradeable.sol";

import {FishcakeEventManagerStorage} from "../core/FishcakeEventManagerStorage.sol";

abstract contract FishcakeEventManager is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    FishcakeEventManagerStorage
{
    //    constructor() {
    //        _disableInitializers();
    //    }

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
        __Ownable_init(_initialOwner);
        _transferOwnership(_initialOwner);
        __ReentrancyGuard_init();
        __FishcakeEventManagerStorage_init(
            _fccAddress,
            _usdtTokenAddr,
            _NFTManagerAddr
        );
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
            _dropNumber <= 101 || _dropNumber <= _totalDropAmts / 10e6,
            "FishcakeEventManager activityAdd: Drop Number Too Large ,Limt 100 or TotalDropAmts/10."
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

        //ifReward There is only one reward in 24 hours
        if (
            (isMint &&
                ifReward() &&
                iNFTManager.getMerchantNTFDeadline(_msgSender()) >
                block.timestamp) ||
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
                if (totalMineAmt > minedAmt) {
                    if (totalMineAmt > minedAmt + tmpBusinessMinedAmt) {
                        aie.businessMinedAmt = tmpBusinessMinedAmt;
                        minedAmt += tmpBusinessMinedAmt;
                        FccTokenAddr.transfer(msg.sender, tmpBusinessMinedAmt);
                        minedAmount = tmpBusinessMinedAmt;
                    } else {
                        aie.businessMinedAmt = totalMineAmt - minedAmt;
                        minedAmt += aie.businessMinedAmt;
                        FccTokenAddr.transfer(msg.sender, aie.businessMinedAmt);
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

    function deleteMinerMineAmount(address _miner) external {
        //todo only nft manager can do this operate
        delete minerMineAmount[_miner];
    }

    // ======================= internal =======================
    function getCurrentMinePercent()
        internal
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

    function ifReward() internal view returns (bool _ret) {
        if (NTFLastMineTime[_msgSender()] == 0) {
            _ret = true;
        } else if (NTFLastMineTime[_msgSender()] - oneDay >= 0) {
            _ret = true;
        } else {
            _ret = false;
        }
    }
}
