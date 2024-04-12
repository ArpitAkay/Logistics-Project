// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";

interface IDisputedServiceRequest {
    function saveDisutedServiceRequest(address from, Types.ServiceRequestInfo memory serviceRequestInfo) external;
}