// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";

library Events {
    event ServiceRequestCreated(Types.ServiceRequestInfo serviceRequestInfo, address createdBy, string message);
    event ServiceRequestUpdated(Types.ServiceRequestInfo updateServiceRequestInfo, address updatedBy, string message);
    event ServiceRequestCancelled(string serviceRequestId, address cancelledBy, string message);
    event BiddedSuccessfully(string serviceRequestId, address biddedBy, uint256 serviceFee);
    event IncreasedAuctionTimeForSR(string serviceRequestId, address increasedBy, string message);
    event AuctionResult(string serviceRequestId, address wonBy, string message);
    event UpdatedSRStatus(string serviceRequestId, address updatedBy, string message);
    event DisputedSRResult(string serviceRequestId, string message);
}