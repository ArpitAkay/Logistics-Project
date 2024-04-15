// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

library Types {

    struct RoleRequest {
        string requestId;
        address applicantAddress;
        Role requestedRole;
        RequestStatus requestStatus;
        address approverAddress;
    }

    enum Role{
        None, Admin, Shipper, Driver, Receiver
    }

    enum RequestStatus {
        Pending, Approved, Rejected
    }

    struct User {
        string userName;
        address userAddress;
        string geoHash;
        uint starsInInt;
        string starsInString;
        Role[] role; 
    }

    struct RoleRequestWithIndexDto {
        RoleRequest roleRequest;
        uint index;
    }
}