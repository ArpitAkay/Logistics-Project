// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";

interface IDisputedServiceRequest {
    function saveDisutedServiceRequest(address from, Types.ServiceRequestInfo memory serviceRequestInfo) external;
    function getDisputedServiceRequestById(string memory _serviceRequestId) external view returns (Types.ServiceRequestInfo memory);
    function decideWinner(string memory _serviceRequestId) external returns (Types.ServiceRequestInfo memory);
}