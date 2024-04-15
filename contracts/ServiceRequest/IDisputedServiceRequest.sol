// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";

interface IDisputedServiceRequest {
    function saveDisputedServiceRequest(address from, Types.ServiceRequestInfo memory serviceRequestInfo) external;
    function decideWinner(string memory _serviceRequestId) external returns (Types.ServiceRequestInfo memory);
}