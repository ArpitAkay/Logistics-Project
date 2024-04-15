// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

interface IDrivingLicenseNFT {
    function validateNFT(address _addr) external view returns (bool);
}