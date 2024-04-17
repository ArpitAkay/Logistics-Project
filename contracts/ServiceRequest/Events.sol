// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";

library Events {
    event ServiceRequestCreated(Types.ServiceRequestInfo serviceRequestInfo, address createdBy, string message);
    event ServiceRequestUpdated(Types.ServiceRequestInfo updateServiceRequestInfo, address updatedBy, string message);
    event BiddedSuccessfully(string serviceRequestId, address biddedBy, uint256 serviceFee);
    event ServiceRequestCancelled(string serviceRequestId, address cancelledBy);
    event IncreasedAuctionTimeForSR(string serviceRequestId, address increaseBy, string message);
    event AuctionResult(string serviceRequestId, address driverAddress, string message);
    event CargoValueRefunded(address from, address to, uint256 cargoAmountValue);
    event UpdatedSRStatus(string serviceRequestId, address updatedBy, string message);
    event DisputedSRResult(string serviceRequestId, string message);
}