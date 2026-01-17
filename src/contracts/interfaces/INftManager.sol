// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INftManager {
    error MineAmountNotEnough(uint256 amount);

    function createNFT(
        string memory _businessName,
        string memory _description,
        string memory _imgUrl,
        string memory _businessAddress,
        string memory _website,
        string memory _social,
        uint8 _type
    ) external returns (bool, uint256);

    function mintBoosterNFT(uint8 nft_type) external returns (bool, uint256);

    function setUriPrefix(string memory _uriPrefix) external;

    function setValues(uint256 _merchantValue, uint256 _userValue) external;

    function withdrawToken(
        address _tokenAddr,
        address _account,
        uint256 _value
    ) external returns (bool);

    function withdrawNativeToken(
        address payable _recipient,
        uint256 _amount
    ) external returns (bool);

    function getMerchantNTFDeadline(
        address _account
    ) external view returns (uint256);

    function getUserNTFDeadline(
        address _account
    ) external view returns (uint256);

    function inActiveMinerBoosterNft(address _miner, uint256 tokenId) external;

    function getActiveMinerBoosterNft(
        address _miner
    ) external view returns (uint256);

    function getMinerBoosterNftType(
        uint256 tokenId
    ) external view returns (uint8);
}
