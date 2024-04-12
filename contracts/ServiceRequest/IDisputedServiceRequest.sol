// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IDisputedServiceRequest {
    function saveDisutedServiceRequest(address from, Types.ServiceRequestInfo memory serviceRequestInfo) external;
}