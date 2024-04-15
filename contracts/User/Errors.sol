// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

library Errors {

    error UserNotRegistered(address userAddress, string errMsg);
    error RoleRequestNotFound(address userAddress, string errMsg, string requestId);
    error NotAuthorized(address userAddress, string errMsg);
    error AlreadyProcessedError(address userAddress, string errMsg, string requestId);
    error InvalidInput(address userAddress, string errMsg);
    error NFTNotFound(address userAddress, string errMsg);
}