// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./Types.sol";

library Events {

    event NewUserCreated(string userName, address userAddr, string geoHash);
    event NewRoleRequestCreated(string requestId, address applicantAddress, Types.Role requestedRole);
}