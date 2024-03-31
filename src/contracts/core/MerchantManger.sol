// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {INFTManager} from "../interfaces/INFTManager.sol";

contract MerchantManger is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    //IERC20 constant public FccTokenAddr = IERC20(0x67AAFdb3aD974A6797D973F00556c603485F7158);
    IERC20 public FccTokenAddr;
    INFTManager public iNFTManager;
    uint256 public immutable totalMineAmt = 300_000_000 * 10 ** 18; // 总挖矿数量
    uint256 public minedAmt = 0; // 已挖数量
    uint8 public minePercent = 50; // 挖矿百分比

    struct ActivityInfo {
        uint256 activityId; // 活动ID
        address businessAccount; // 发起人账户（商家0x...）
        string businessName; // 商家名称
        string activityContent; // 活动内容
        string latitudeLongitude; // 经纬度，以_分割经纬度
        uint256 activityCreateTime; // 活动创建时间
        uint256 activityDeadLine; // 活动结束时间
        uint8 dropType; // 奖励规则：1表示平均获得  2表示随机
        uint256 dropNumber; // 奖励份数
        uint256 minDropAmt; // 当dropType为1时，填0，为2时，填每份最少领取数量
        uint256 maxDropAmt; // 当dropType为1时，填每份奖励数量，为2时，填每份最多领取数量，奖励总量根据该字段 * 奖励份数确定
        address tokenContractAddr; //Token Contract Address，For example, USDT contract address: 0x55d398326f99059fF775485246999027B3197955
    }

    ActivityInfo[] public activityInfoArrs; // 所有活动数组

    struct ActivityInfoExt {
        uint256 activityId; // 活动ID
        uint256 alreadyDropAmts; // 总共已奖励数量
        uint256 alreadyDropNumber; // 总共已奖励份数
        uint256 businessMinedAmt; // 商家获得的挖矿奖励
        uint256 businessMinedWithdrawedAmt; // 商家已提取的挖矿奖励
        uint8 activityStatus; // 活动状态：1表示进行中  2表示已结束
    }

    ActivityInfoExt[] public activityInfoExtArrs; // 所有活动数组

    uint256[] public activityInfoChangedIdx; // 状态有改变的下标

    struct DropInfo {
        uint256 activityId; // 活动ID
        address userAccount; // 发起人账户（商家0x...）
        uint256 dropTime; // 获奖时间
        uint256 dropAmt; // 获奖数量
    }

    DropInfo[] public dropInfoArrs; // 所有获奖数组

    // 活动ID => 用户 => 是否已获得过奖励
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
    event ActivityFinish(uint256 indexed _activityId);
    event Drop(
        address indexed who,
        uint256 indexed _activityId,
        uint256 _dropAmt
    );
    event WithdrawUToken(
        address indexed who,
        address indexed _tokenAddr,
        address indexed _account,
        uint256 _value
    );
    event SetValidTime(address indexed who, uint256 _time);

    event Wthdraw(address indexed who, uint256 _amount);
    event Received(address indexed who, uint _value);

    constructor(
        address initialOwner,
        address _fccAddress,
        address _NFTManagerAddr
    ) Ownable(initialOwner) {
        FccTokenAddr = IERC20(_fccAddress);
        iNFTManager = INFTManager(_NFTManagerAddr);
    }

    /*
        增加活动，任何人都可以增加
        参数：
        _businessName 商家名称
        _activityContent 活动内容
        _latitudeLongitude 商家地址经纬度，以_分割经纬度
        _activityDeadLine 活动结束时间，需传TimeStamp到后端（如：1683685034）
        _totalDropAmts  总奖励数量，根据_maxDropAmt * _dropNumber得到，不用用户输入 （调用合约时，需将用户输入的数字 * 10的18次方）
        _dropType     奖励规则：1表示平均获得  2表示随机
        _dropNumber      奖励份数
        _minDropAmt     当dropType为1时，填0，为2时，填每份最少领取数量  （调用合约时，需将用户输入的数字 * 10的18次方）
        _maxDropAmt     当dropType为1时，填每份奖励数量，为2时，填每份最多领取数量，奖励总量根据该字段 * 奖励份数确定  （调用合约时，需将用户输入的数字 * 10的18次方）
        _tokenContractAddr    Token Contract Address，For example, USDT contract address: 0x55d398326f99059fF775485246999027B3197955
        返回值：
        _ret   是否成功
        _activityId  活动ID
        注：前端调用该方法前，需先调用FCCToken的approve方法，授权本合约地址，访问使用者钱包的FCCToken访问权限。
        具体授权数字，使用 _maxDropAmt * 10的18次方 * _dropNumber
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
        require(_totalDropAmts > 0, "Drop Amount Error.");

        require(
            _totalDropAmts == _maxDropAmt * _dropNumber,
            "Drop Number Not Meet Total Drop Amounts."
        );

        // 转币到本合约锁定
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
        商家结束活动
        参数：
        _activityId  活动ID
        返回值：
        _ret  是否成功
    */
    function activityFinish(
        uint256 _activityId
    ) public nonReentrant returns (bool _ret) {
        ActivityInfo storage ai = activityInfoArrs[_activityId - 1];

        ActivityInfoExt storage aie = activityInfoExtArrs[_activityId - 1];

        require(ai.businessAccount == _msgSender(), "Not The Owner.");
        require(aie.activityStatus == 1, "Activity Status Error.");

        aie.activityStatus = 2;

        if (ai.maxDropAmt * ai.dropNumber > aie.alreadyDropAmts) {
            IERC20(ai.tokenContractAddr).safeTransfer(
                _msgSender(),
                ai.maxDropAmt * ai.dropNumber - aie.alreadyDropAmts
            );
        }
        if (
            iNFTManager.getMerchantNTFDeadline(_msgSender()) >
            block.timestamp ||
            iNFTManager.getUserNTFDeadline(_msgSender()) > block.timestamp
        ) {
            //获取当前挖取代币百分比
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
                // 对于在平台上托管的每个FCC释放活动，活动发起人可以基于活动消耗的总代币数量的50％，或者参与者总数乘以20的50％，以较低的值为准来挖取代币。
                uint256 tmpDropedVal = aie.alreadyDropNumber * 20 * 1e18;
                uint256 tmpBusinessMinedAmt = ((
                    aie.alreadyDropAmts > tmpDropedVal
                        ? tmpDropedVal
                        : aie.alreadyDropAmts
                ) * percent) / 100;
                if (totalMineAmt >= minedAmt + tmpBusinessMinedAmt) {
                    aie.businessMinedAmt = tmpBusinessMinedAmt;
                    minedAmt += tmpBusinessMinedAmt;
                    FccTokenAddr.safeTransfer(
                        _msgSender(),
                        tmpBusinessMinedAmt
                    );
                }
            }
        }

        activityInfoChangedIdx.push(_activityId - 1);

        emit ActivityFinish(_activityId);

        _ret = true;
    }

    /*
        奖励发放（商家给会员发放奖励）
        参数：
        _activityId  活动ID
        _userAccount 终端用户地址
        _dropAmt     奖励数量，如果活动的dropType是随机时，需填写该数量，因为合约随机数生成非常消耗资源，平均获得时，无需填写  ;     // 奖励规则：1表示平均获得  2表示随机
        返回值：
        _ret 是否成功
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

    function withdrawUToken(
        address _tokenAddr,
        address _account,
        uint256 _value
    ) public onlyOwner nonReentrant returns (bool _ret) {
        require(_tokenAddr != address(0x0), "token address error.");
        require(
            IERC20(_tokenAddr).balanceOf(address(this)) >= _value,
            "Balance not enough."
        );

        IERC20(_tokenAddr).safeTransfer(_account, _value);
        _ret = true;
        emit WithdrawUToken(_msgSender(), _tokenAddr, _account, _value);
    }

    function withdraw(
        address payable _recipient,
        uint256 _amount
    ) public onlyOwner nonReentrant returns (bool _ret) {
        require(_recipient != address(0x0), "recipient address error.");
        require(_amount <= address(this).balance, "Balance not enough.");
        (_ret, ) = _recipient.call{value: _amount}("");
        emit Wthdraw(_recipient, _amount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
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
        if (minedAmt < 30_000_000 * 1e18) {
            currentMinePercent = 50;
        } else if (minedAmt < 100_000_000 * 1e18) {
            currentMinePercent = 40;
        } else if (minedAmt < 200_000_000 * 1e18) {
            currentMinePercent = 20;
        } else if (minedAmt < 300_000_000 * 1e18) {
            currentMinePercent = 10;
        } else {
            currentMinePercent = 0;
        }
    }
}
