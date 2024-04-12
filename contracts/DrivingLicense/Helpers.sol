// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library Helpers {
    function substring(string memory str, uint startIndex, uint length) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex + length <= strBytes.length, "Invalid substring range");
        
        bytes memory result = new bytes(length);
        for (uint i = 0; i < length; i++) {
            result[i] = strBytes[startIndex + i];
        }
        
        return string(result);
    }

    function formatDrivingLicenseNumber(string memory input) internal pure returns (string memory) {
        string memory lastTwo = Helpers.substring(input, bytes(input).length - 2, 2);

        string memory firstChars = "";
        for(uint256 i=0; i<bytes(input).length-2; i++) {
            if (bytes(input)[i] == bytes(" ")[0]) {
                firstChars = string(abi.encodePacked(firstChars, " "));
            } else {
                firstChars = string(abi.encodePacked(firstChars, "*"));
            }
        }

        string memory formattedDL = string(abi.encodePacked(firstChars, lastTwo));
        
        return formattedDL;
    }
}