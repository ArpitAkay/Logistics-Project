// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./Types.sol";
import "./Helpers.sol";
import "./Errors.sol";


contract DrivingLicenseNFT is ERC721, ERC721Enumerable, ERC721Pausable, Ownable, ERC721Burnable {
    bool internal publicMintOpen = false;

    uint256 private _nextTokenId;
    uint256 internal publicMintPrice = 0.01 ether;
    uint256 internal maxSupply = 200;

    mapping (uint256 => Types.DrivingLicenseInfo) internal drivingLicenseInfo;
    mapping (address => bool) internal peopleWhoAlreadyMintedNft;

    constructor(address initialOwner)
        ERC721("DrivingLicense", "DL")
        Ownable(initialOwner)
    {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://Qmcp8L1Fh4UWicvAFG3hEwu6vjeJ5v8XfAHNKZEUX7HcRy/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function editMintWindows(bool _publicMintOpen) external onlyOwner {
        publicMintOpen = _publicMintOpen;
    }

    function editMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function publicMint(string memory _driverName, string memory _driverLicenseNumber, string memory ipfsHash) external payable {
        require(publicMintOpen, "Public mint is closed");
        require(msg.value == publicMintPrice, "Not enough funds");
        uint256 tokenId = internalMint(msg.sender);
        string memory dlNumber = Helpers.formatDrivingLicenseNumber(_driverLicenseNumber);
        drivingLicenseInfo[tokenId] = Types.DrivingLicenseInfo(_driverName, dlNumber, ipfsHash);
    }

    function internalMint(address to) internal returns (uint256) {
        require(!peopleWhoAlreadyMintedNft[msg.sender], "You have already minted driving NFT");
        peopleWhoAlreadyMintedNft[msg.sender] = true;
        require(totalSupply() < maxSupply, "We sold out");
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function burn(uint256 _tokenId) public override  {
        address _addr = ownerOf(_tokenId);
        super.burn(_tokenId);
        delete drivingLicenseInfo[_tokenId];
        peopleWhoAlreadyMintedNft[_addr] = false;
    }

    function burnViaOwner(uint256 _tokenId) public onlyOwner {
        address _addr = ownerOf(_tokenId);
        super._burn(_tokenId);
        delete drivingLicenseInfo[_tokenId];
        peopleWhoAlreadyMintedNft[_addr] = false;
    }

    function validateNFT() external view returns (bool) {
        uint256 totalOwned = balanceOf(msg.sender);
        uint256[] memory ownedTokens = new uint256[](totalOwned);

        for (uint256 i = 0; i < totalOwned; i++) {
            ownedTokens[i] = tokenOfOwnerByIndex(msg.sender, i);
        }

        for(uint256 i=0; i<ownedTokens.length; i++) {
            if(bytes(drivingLicenseInfo[ownedTokens[i]].driverName).length > 0 && bytes(drivingLicenseInfo[ownedTokens[i]].driverLicenseNumber).length > 0) {
                return true;
            }
        }

        return false;
    }

    function getDriverLicenseInfoByTokenId(uint256 _tokenId) public view returns (Types.DrivingLicenseInfo memory) {
        if(bytes(drivingLicenseInfo[_tokenId].driverLicenseNumber).length == 0) {
            revert Errors.DriverLicenseInfoNotFound({tokenId : _tokenId, message: "Driver License info not found"});
        }

        return drivingLicenseInfo[_tokenId];
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
