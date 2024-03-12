// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin-upgrades/contracts/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @custom:oz-upgrades-from NFTManager
contract NFTManagerUpgrades is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Strings for uint256;
    using SafeERC20 for IERC20;
    uint256 private _nextTokenId;
    string public uriPrefix;
    uint256 private merchantValue;
    uint256 private userValue;
    //30 days = 2592000 s
    uint256 private validTime;
    IERC20 public FccTokenAddr;
    IERC20 public UsdtTokenAddr;
    mapping(address => uint256) public merchantNTFDeadline;
    mapping(address => uint256) public userNTFDeadline;
    uint256 public newDta;

    //tokenId => deadline timestamp
    //mapping(uint256 => uint256)  public nftDeadline;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    event UriPrefixSet(address indexed who, string urlPrefix);
    event SetValues(
        address indexed who,
        uint256 _merchantValue,
        uint256 _userValue
    );
    event MintNewEvent(
        address indexed _who,
        uint256 _tokenId,
        string _businessName,
        string _description,
        string _imgUrl,
        string _businessAddress,
        string _webSite,
        string _social,
        uint256 _value,
        uint8 _type
    );
    event WithdrawUToken(
        address indexed who,
        address indexed _account,
        uint256 indexed _value
    );
    event SetValidTime(address indexed who, uint256 _time);

    function initialize(
        address initialOwner,
        address _fccAddress,
        address _usdtAddress
    ) public initializer {
        __ERC721_init("FCCNFT", "FCCNFT");
        __Ownable_init(initialOwner);
        FccTokenAddr = IERC20(_fccAddress);
        UsdtTokenAddr = IERC20(_usdtAddress);
        merchantValue = 80e18;
        userValue = 8e18;
        validTime = 2592000;
    }

    function mintNewEvent(
        string memory _businessName,
        string memory _description,
        string memory _imgUrl,
        string memory _businessAddress,
        string memory _webSite,
        string memory _social,
        uint8 _type
    ) public nonReentrant returns (bool _ret, uint256 _tokenId) {
        require(_type == 2 || _type == 1, "Type Error.");
        if (_type == 1)
            require(
                UsdtTokenAddr.allowance(_msgSender(), address(this)) >=
                    merchantValue,
                "Approve token not enough Error."
            );
        else
            require(
                UsdtTokenAddr.allowance(_msgSender(), address(this)) >=
                    userValue,
                "Approve token not enough Error."
            );

        uint256 _value = (_type == 1 ? merchantValue : userValue);

        if (_type == 1)
            merchantNTFDeadline[_msgSender()] = (block.timestamp + validTime);
        else userNTFDeadline[_msgSender()] = (block.timestamp + validTime);

        UsdtTokenAddr.safeTransferFrom(_msgSender(), address(this), _value);

        uint256 tokenId = _nextTokenId++;
        _safeMint(_msgSender(), tokenId);

        emit MintNewEvent(
            _msgSender(),
            tokenId,
            _businessName,
            _description,
            _imgUrl,
            _businessAddress,
            _webSite,
            _social,
            _value,
            _type
        );
        _ret = true;
        _tokenId = tokenId;
    }

    function safeMint(address to) private nonReentrant {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable) returns (string memory) {
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setUriPrefix(
        string memory _uriPrefix
    ) external onlyOwner returns (bool _ret) {
        uriPrefix = _uriPrefix;
        _ret = true;
        emit UriPrefixSet(_msgSender(), _uriPrefix);
    }

    function setValues(
        uint256 _merchantValue,
        uint256 _userValue
    ) public onlyOwner returns (bool _ret) {
        merchantValue = _merchantValue;
        userValue = _userValue;
        _ret = true;
        emit SetValues(_msgSender(), _merchantValue, _userValue);
    }

    function withdrawUToken(
        address _account,
        uint256 _value
    ) public onlyOwner nonReentrant returns (bool _ret) {
        require(
            UsdtTokenAddr.balanceOf(address(this)) >= _value,
            "Balance not enough."
        );
        UsdtTokenAddr.safeTransfer(_account, _value);
        _ret = true;
        emit WithdrawUToken(_msgSender(), _account, _value);
    }

    function getMerchantNTFDeadline(
        address _account
    ) public view returns (uint256) {
        return merchantNTFDeadline[_account];
    }

    function getUserNTFDeadline(
        address _account
    ) public view returns (uint256) {
        return userNTFDeadline[_account];
    }

    function getUTokenBalance() public view onlyOwner returns (uint256) {
        return UsdtTokenAddr.balanceOf(address(this));
    }

    function setValidTime(uint256 _time) public onlyOwner returns (bool _ret) {
        validTime = _time;
        _ret = true;
        emit SetValidTime(_msgSender(), _time);
    }

    function setNewData() public {
        newDta = 666666;
    }

    function getNewData() public returns (uint256) {
        return newDta;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
