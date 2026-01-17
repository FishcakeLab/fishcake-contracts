// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgrades/contracts/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "../../history/NftManagerV4.sol";

/// @custom:oz-upgrades-from NftManagerV4
contract NftManagerV5 is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    NftManagerStorage
{
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
    event Received(address indexed receiver, uint256 _value);

    event UpdatedNftJson(
        address indexed creator,
        uint8 nftType,
        string newJsonUrl
    );
    event NameSymbolUpdated(string newName, string newSymbol);

    event MintBoosterNFT(
        address indexed miner,
        uint256 indexed tokenId,
        uint8 nftType,
        uint256 usedFishCakePower,
        uint256 mintTime
    );

    modifier onlyBooster() {
        require(
            msg.sender == boosterAddress,
            "MessageManager: only booster address can do this operate"
        );
        _;
    }

    modifier onlyStakingManager() {
        require(
            msg.sender == address(stakingManagerAddress),
            "MessageManager: only staking manager can do this operate"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _initialOwner,
        address _fccTokenAddr,
        address _tokenUsdtAddr,
        address _redemptionPoolAddress
    ) public initializer {
        require(
            _initialOwner != address(0),
            "NftManager initialize: _initialOwner can't be zero address"
        );
        __ERC721_init("Fishcake Pass NFT", "FNFT");
        __Ownable_init(_initialOwner);
        __ReentrancyGuard_init();
        _transferOwnership(_initialOwner);
        __NftManagerStorage_init(
            _fccTokenAddr,
            _tokenUsdtAddr,
            _redemptionPoolAddress
        );
    }

    /// @custom:oz-upgrades-validate-as-initializer
    function initializeV5(
        address _stakingManagerAddress
    ) public reinitializer(5) {
        stakingManagerAddress = IStakingManager(_stakingManagerAddress);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function nftUpgradeInit(
        address _feManagerAddress,
        address _boosterAddress,
        address _stakingManagerAddress
    ) external onlyOwner {
        uncommonFishcakeNftJson = "https://www.fishcake.org/image/3.json";
        rareShrimpNftJson = "https://www.fishcake.org/image/4.json";
        epicSalmonNftJson = "https://www.fishcake.org/image/5.json";
        legendaryTunaNftJson = "https://www.fishcake.org/image/6.json";

        uncommonFishcakeNftJson_Used = "https://www.fishcake.org/image/13.json";
        rareShrimpNftJson_Used = "https://www.fishcake.org/image/14.json";
        epicSalmonNftJson_Used = "https://www.fishcake.org/image/15.json";
        legendaryTunaNftJson_Used = "https://www.fishcake.org/image/16.json";

        feManagerAddress = IFishcakeEventManager(_feManagerAddress);
        stakingManagerAddress = IStakingManager(_stakingManagerAddress);
        boosterAddress = _boosterAddress;
    }

    function mintBoosterNFT(
        uint8 nft_type
    ) external nonReentrant returns (bool, uint256) {
        uint256 mineFishCakePower = feManagerAddress.getMinedFishcakePower(
            msg.sender
        );
        if (mineFishCakePower < 30 * 1e6) {
            revert MineAmountNotEnough(mineFishCakePower);
        }
        uint256 usedFishCakePower;
        uint256 boosterTokenId = _nextTokenId++;
        _safeMint(msg.sender, boosterTokenId);
        uint256 decimal = 1e6;
        if (nft_type == 3) {
            usedFishCakePower = 60 * decimal;
            nftMintType[boosterTokenId] = 3;
        } else if (nft_type == 4) {
            usedFishCakePower = 300 * decimal;
            nftMintType[boosterTokenId] = 4;
        } else if (nft_type == 5) {
            usedFishCakePower = 800 * decimal;
            nftMintType[boosterTokenId] = 5;
        } else if (nft_type == 6) {
            usedFishCakePower = 1500 * decimal;
            nftMintType[boosterTokenId] = 6;
        }
        require(
            mineFishCakePower >= usedFishCakePower,
            "NftManager mintBoosterNFT: Fishcake power not enough"
        );
        feManagerAddress.updateMinedFishcakePower(
            msg.sender,
            mineFishCakePower - usedFishCakePower
        );

        minerActiveNft[msg.sender] = boosterTokenId;
        nftOwner[boosterTokenId] = msg.sender;

        minerHistoryBoosterNft[msg.sender].push(boosterTokenId);

        emit MintBoosterNFT(
            msg.sender,
            boosterTokenId,
            nft_type,
            usedFishCakePower,
            block.timestamp
        );

        return (true, boosterTokenId);
    }

    function createNFT(
        string memory _businessName,
        string memory _description,
        string memory _imgUrl,
        string memory _businessAddress,
        string memory _website,
        string memory _social,
        uint8 _type
    ) external nonReentrant returns (bool, uint256) {
        require(
            _type == 1 || _type == 2,
            "NftManager createNFT: type can only equal 1 and 2, 1 stand for merchant, 2 stand for personal user"
        );
        require(
            merchantValue > 0 && userValue > 0,
            "NftManager createNFT: MerchantValue and UserValue must be set first"
        );
        require(
            validTime > 0,
            "NftManager createNFT: validTime must be set first"
        );
        uint256 payUsdtAmount = _type == 1 ? merchantValue : userValue;
        uint256 nftDeadline = block.timestamp + validTime;
        if (_type == 1) {
            require(
                tokenUsdtAddr.allowance(msg.sender, address(this)) >=
                    merchantValue,
                "NftManager createNFT: Merchant allowance must more than 80 U"
            );
            merchantNftDeadline[msg.sender] = nftDeadline;
            fccTokenAddr.transfer(msg.sender, proMineAmt);
        } else {
            require(
                tokenUsdtAddr.allowance(msg.sender, address(this)) >= userValue,
                "NftManager createNFT: User allowance must more than 8 U"
            );
            userNftDeadline[msg.sender] = nftDeadline;
            fccTokenAddr.transfer(msg.sender, basicMineAmt);
        }

        tokenUsdtAddr.safeTransferFrom(
            msg.sender,
            address(this),
            payUsdtAmount
        );
        tokenUsdtAddr.safeTransfer(
            address(redemptionPoolAddress),
            (payUsdtAmount * 25) / 100
        );

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        nftMintType[tokenId] = _type;

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

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        require(
            _ownerOf(tokenId) != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint8 nftType = nftMintType[tokenId];
        if (nftType == 1) {
            return proNftJson;
        } else if (nftType == 2) {
            return basicNftJson;
        } else if (nftType == 3) {
            return uncommonFishcakeNftJson;
        } else if (nftType == 4) {
            return rareShrimpNftJson;
        } else if (nftType == 5) {
            return epicSalmonNftJson;
        } else if (nftType == 6) {
            return legendaryTunaNftJson;
        } else if (nftType == 13) {
            return uncommonFishcakeNftJson_Used;
        } else if (nftType == 14) {
            return rareShrimpNftJson_Used;
        } else if (nftType == 15) {
            return epicSalmonNftJson_Used;
        } else if (nftType == 16) {
            return legendaryTunaNftJson_Used;
        } else {
            return "";
        }
    }

    function uri(
        uint256 inputTokenId
    ) public view virtual returns (string memory) {
        return tokenURI(inputTokenId);
    }

    // don't use 20241016 1630
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // don't use 20241016 1630
    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
        emit UriPrefixSet(msg.sender, _uriPrefix);
    }

    function setValues(
        uint256 _merchantValue,
        uint256 _userValue
    ) external onlyOwner {
        merchantValue = _merchantValue;
        userValue = _userValue;
        emit SetValues(msg.sender, _merchantValue, _userValue);
    }

    function withdrawToken(
        address _tokenAddr,
        address _account,
        uint256 _value
    ) external onlyOwner nonReentrant returns (bool) {
        require(
            _tokenAddr != address(0x0),
            "NftManager withdrawToken:token address error."
        );
        require(
            IERC20(_tokenAddr).balanceOf(address(this)) >= _value,
            "NftManager withdrawToken: Balance not enough."
        );

        IERC20(_tokenAddr).transfer(_account, _value);

        emit WithdrawUToken(msg.sender, _tokenAddr, _account, _value);

        return true;
    }

    function withdrawNativeToken(
        address payable _recipient,
        uint256 _amount
    ) public onlyOwner nonReentrant returns (bool) {
        require(
            _recipient != address(0x0),
            "NftManager withdrawNativeToken: recipient address error."
        );
        require(
            _amount <= address(this).balance,
            "NftManager withdrawNativeToken: Balance not enough."
        );
        (bool _ret, ) = _recipient.call{value: _amount}("");
        emit Withdraw(_recipient, _amount);
        return _ret;
    }

    function getMerchantNTFDeadline(
        address _account
    ) public view returns (uint256) {
        return merchantNftDeadline[_account];
    }

    function getUserNTFDeadline(
        address _account
    ) public view returns (uint256) {
        return userNftDeadline[_account];
    }

    function inActiveMinerBoosterNft(
        address _miner,
        uint256 tokenId
    ) external onlyStakingManager {
        require(nftOwner[tokenId] == _miner, "Invalid tokenId");

        // uint256 activeNftId = minerActiveNft[_miner];
        uint256 nftType = nftMintType[tokenId];
        require(nftType >= 3 && nftType <= 6, "No active booster NFT");

        nftMintType[tokenId] += 10;
    }

    function getActiveMinerBoosterNft(
        address _miner
    ) external view returns (uint256) {
        return minerActiveNft[_miner];
    }

    function getMinerBoosterNftType(
        uint256 tokenId
    ) external view returns (uint8) {
        return nftMintType[tokenId];
    }

    function getTokenBalance(
        address tokenAddress
    ) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function updateNftJson(
        uint8 _type,
        string memory _newJsonUrl
    ) external onlyOwner {
        require(_type == 1 || _type == 2, "Invalid NFT type");
        if (_type == 1) {
            proNftJson = _newJsonUrl;
        } else {
            basicNftJson = _newJsonUrl;
        }
        emit UpdatedNftJson(msg.sender, _type, _newJsonUrl);
    }

    function updateNameAndSymbol(
        string memory newName,
        string memory newSymbol
    ) external onlyOwner {
        _customName = newName;
        _customSymbol = newSymbol;
        emit NameSymbolUpdated(newName, newSymbol);
    }

    function name() public view virtual override returns (string memory) {
        return bytes(_customName).length > 0 ? _customName : super.name();
    }

    function symbol() public view virtual override returns (string memory) {
        return bytes(_customSymbol).length > 0 ? _customSymbol : super.symbol();
    }
}
