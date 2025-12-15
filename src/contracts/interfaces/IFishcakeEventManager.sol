// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFishcakeEventManager {
    // ======= event ==========
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

    // ======= function ==========
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
    ) external returns (bool, uint256);

    function activityFinish(uint256 _activityId) external returns (bool);

    function drop(
        uint256 _activityId,
        address _userAccount,
        uint256 _dropAmt
    ) external returns (bool);

    function getMinerMineAmount(address _miner) external view returns (uint256);

    function deleteMinerMineAmount(address _miner) external;

    function getMinedFishcakePower(
        address _miner
    ) external view returns (uint256);

    function deleteMinedFishcakePower(address _miner) external;

    function updateMinedFishcakePower(address _miner, uint256 _power) external;
}
