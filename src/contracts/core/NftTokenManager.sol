// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import 'solmate/utils/MerkleProofLib.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {ERC721A} from 'erc721a/ERC721A.sol';


contract NftTokenManager is ERC721A, Ownable, AccessControl {
    using Strings for uint256;
    uint256 public supplyLimit;
    bytes32 public merkleRoot;
    bool public allowlistMintActive;
    bool public burnActive;
    string public uriPrefix;

    bytes32 public immutable MINTER_ROLE = keccak256('MINTER');
    bytes32 public immutable PAUSER_ROLE = keccak256('PAUSER');

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert ("Only admin can do this operate");
        }
        _;
    }

    modifier onlyRoleOrAdmin(bytes32 role) {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) && !hasRole(role, _msgSender())) {
            revert ("Missing role or admin");
        }
        _;
    }

    event SupplyLimitSet(address indexed changedBy, uint256 supplyLimit);
    event BurnActiveSet(address indexed changedBy, bool burnActive);
    event AllowlistMintSet(address indexed changedBy, bool AllowlistMint);
    event MerkleRootSet(address indexed changedBy, bytes32 root);
    event UriPrefixSet(address indexed changedBy, string urlPrefix);

    error BurnNotActive();
    error NotOwner();

    constructor(uint256 _supplyLimit, bytes32 _merkleRoot) ERC721A('FishCakeNFT', 'FCK') Ownable(msg.sender) {
        supplyLimit = _supplyLimit;
        merkleRoot = _merkleRoot;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function allowlistMint(bytes32[] calldata proof) external {
        if (!allowlistMintActive) revert ("Allow list mint not active");
        if (hasMinted(msg.sender)) revert ("Mint limit reached");
        if (_totalMinted() >= supplyLimit) revert ("Supply limit reached");
        if (
            !MerkleProofLib.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert ("Invalid merkle proof");
        _safeMint(msg.sender, 1);
    }

    function batchMintRemainingTokens(address receiver, uint256 amount) external onlyRoleOrAdmin(MINTER_ROLE) {
        if (_totalMinted() + amount > supplyLimit) revert ("Supply limit reached");
        _safeMint(receiver, amount);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function hasMinted(address owner) public view returns (bool) {
        return _numberMinted(owner) > 0;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : '';
    }

    function burn(uint256 tokenId) external {
        if (!burnActive) revert BurnNotActive();
        if (ownerOf(tokenId) != msg.sender) revert NotOwner();
        _burn(tokenId);
    }

    function setMaxSupply(uint256 _supplyLimit) external onlyAdmin {
        if (_supplyLimit < _totalMinted()) revert ("Invalid supply");
        supplyLimit = _supplyLimit;
        emit SupplyLimitSet(msg.sender, _supplyLimit);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyAdmin {
        merkleRoot = _merkleRoot;
        emit MerkleRootSet(msg.sender, _merkleRoot);
    }

    function setBurn(bool _burnActive) external onlyAdmin {
        burnActive = _burnActive;
        emit BurnActiveSet(msg.sender, _burnActive);
    }

    function setAllowlistMint(bool status) external onlyRoleOrAdmin(PAUSER_ROLE) {
        allowlistMintActive = status;
        emit AllowlistMintSet(msg.sender, status);
    }

    function setUriPrefix(string memory _uriPrefix) external onlyAdmin {
        uriPrefix = _uriPrefix;
        emit UriPrefixSet(msg.sender, _uriPrefix);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        if (!_exists(tokenId)) {
            revert ("ERC721 non existent token");
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
