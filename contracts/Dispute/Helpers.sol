// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

library Helpers {
    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function generateRandomString(uint256 _length) internal view returns (string memory) {
        bytes memory characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        bytes memory randomString = new bytes(_length);
        uint256 charLength = characters.length;

        for (uint256 i = 0; i < _length; i++) {
            uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number), i))) % charLength;
            randomString[i] = characters[rand];
        }
        return string(randomString);
    }
    
    function compareGeoHash(string memory _geoHashParent, string memory _geoHashChild) internal pure returns (bool) {
        bytes memory parentBytes = bytes(_geoHashParent);
        bytes memory childBytes = bytes(_geoHashChild);
        
        // Compare lengths
        if (parentBytes.length > childBytes.length) {
            return false;
        }
        
        // Compare prefixes
        for (uint i = 0; i < parentBytes.length; i++) {
            if (parentBytes[i] != childBytes[i]) {
                return false;
            }
        }
        
        return true;
    }
}