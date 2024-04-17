// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Errors {
    error PublicMintError(string driverName, string driverLicenseNumber, string ipfsHash, string message);
    error InternalMintError(address from, address to, string message);
    error DriverLicenseInfoNotFound(uint256 tokenId, string message);
    error YouNotOwnerOfNot(uint256 tokenId, string message);
}