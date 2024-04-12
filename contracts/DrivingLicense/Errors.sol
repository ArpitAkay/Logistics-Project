// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Errors {
    error DriverLicenseInfoNotFound(uint256 tokenId, string message);
    error YouNotOwnerOfNot(uint256 tokenId, string message);
}