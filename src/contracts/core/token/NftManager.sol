// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin-upgrades/contracts/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import "./NftManagerStorage.sol";

contract NftManager is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, NftManagerStorage {
    using Strings for uint256;
    using Strings for uint8;
    using SafeERC20 for IERC20;

    event UriPrefixSet(address indexed setterAddress, string urlPrefix);

    event SetValues(
        address indexed _setterAddress,
        uint256 _merchantValue,
        uint256 _userValue
    );

    event CreateNFT(
        address indexed creator,
        uint256 _tokenId,
        string _businessName,
        string _description,
        string _imgUrl,
        string _businessAddress,
        string _webSite,
        string _social,
        uint256 _value,
        uint256 _deadline,
        uint8 _type
    );

    event WithdrawUToken(
        address indexed withdrawer,
        address indexed _tokenAddr,
        address indexed _account,
        uint256 _value
    );

    event SetValidTime(address indexed setter, uint256 _time);

    event Withdraw(address indexed withdrawer, uint256 _amount);
    event Received(address indexed receiver, uint _value);
    

    constructor(address _fccTokenAddr, address _tokenUsdtAddr, address _redemptionPoolAddress) NftManagerStorage (_fccTokenAddr, _tokenUsdtAddr, _redemptionPoolAddress){
        _disableInitializers();
    }

    function initialize(address _initialOwner) public initializer {
        require(_initialOwner != address(0), "NftManager initialize: _initialOwner can't be zero address");
        __ERC721_init("TheWebThree", "TWT");
        __Ownable_init(_initialOwner);
        _transferOwnership(_initialOwner);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function createNFT(
        string memory _businessName,
        string memory _description,
        string memory _imgUrl,
        string memory _businessAddress,
        string memory _website,
        string memory _social,
        uint8 _type
    ) public nonReentrant returns (bool, uint256) {
        require(_type == 1 || _type == 2, "NftManager createNFT: type can only equal 1 and 2, 1 stand for merchant, 2 stand for personal user");
        uint256 payUsdtAmount = _type == 1 ? merchantValue : userValue;
        uint256 nftDeadline = block.timestamp + validTime;
        if( _type == 1) {
            require(tokenUsdtAddr.allowance(msg.sender, address(this)) > merchantValue, "NftManager createNFT: Merchant allowance must more than 80 U");
            merchantNftDeadline[msg.sender] = nftDeadline;
            fccTokenAddr.transfer(msg.sender, proMineAmt);
        } else {
            require(tokenUsdtAddr.allowance(msg.sender, address(this)) > userValue, "NftManager createNFT: Merchant allowance must more than 8 U");
            userNftDeadline[msg.sender] = nftDeadline;
            fccTokenAddr.transfer(msg.sender, basicMineAmt);
        }

        tokenUsdtAddr.transferFrom(msg.sender, address(this), payUsdtAmount);
        tokenUsdtAddr.transfer(redemptionPoolAddress, (payUsdtAmount * 75) / 100);

        uint256 tokenId = _nextTokenId++;

        _mint(msg.sender, tokenId);

        nftMintType[tokenId] = _type;

        string memory uri = string(
            abi.encodePacked(uriPrefix,   _type.toString(), ".json")
        );

        _setTokenURI(tokenId, uri);

        emit CreateNFT(
            msg.sender,
            tokenId,
            _businessName,
            _description,
            _imgUrl,
            _businessAddress,
            _website,
            _social,
            payUsdtAmount,
            nftDeadline,
            _type
        );
        return (true, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        string memory baseURI = _baseURI();
        uint256 _type = nftMintType[tokenId];
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _type.toString(), ".json")) : "";
    }

    function uri(uint256 uri_) public view virtual returns (string memory) {
        return tokenURI(uri_);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
        emit UriPrefixSet(msg.sender, _uriPrefix);
    }

    function setValues(uint256 _merchantValue, uint256 _userValue) public onlyOwner  {
        merchantValue = _merchantValue;
        userValue = _userValue;
        emit SetValues(msg.sender, _merchantValue, _userValue);
    }

    function withdrawToken(address _tokenAddr, address _account, uint256 _value) public onlyOwner nonReentrant returns (bool) {
        require(_tokenAddr != address(0x0), "NftManager withdrawToken:token address error.");
        require(IERC20(_tokenAddr).balanceOf(address(this)) >= _value, "NftManager withdrawToken: Balance not enough.");

        IERC20(_tokenAddr).transfer(_account, _value);

        emit WithdrawUToken(msg.sender, _tokenAddr, _account, _value);

        return true;
    }

    function withdrawNativeToken(address payable _recipient, uint256 _amount) public onlyOwner nonReentrant returns (bool) {
        require(_recipient != address(0x0), "NftManager withdrawNativeToken: recipient address error.");
        require(_amount <= address(this).balance, "NftManager withdrawNativeToken: Balance not enough.");
        (bool _ret, ) = _recipient.call{value: _amount}("");
        emit Withdraw(_recipient, _amount);
        return _ret;
    }

    function getMerchantNTFDeadline(address _account) public view returns (uint256) {
        return merchantNftDeadline[_account];
    }

    function getUserNTFDeadline(address _account) public view returns (uint256) {
        return userNftDeadline[_account];
    }

    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
