// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";

library Events {
    event ServiceRequestCreated(Types.ServiceRequestInfo serviceRequestInfo, string message);
    event BiddedSuccessfully(string serviceRequestId, uint256 serviceFee, address bidder);
    event ServiceRequestCancelled(string serviceRequestId, address shipperAddr);
    event IncreasedAuctionTimeForSR(string serviceRequestId, string message);
    event AuctionResult(string serviceRequestId, string message);
    event UpdatedSRStatus(string serviceRequestId, string message);
    event CargoValueRefunded(address from, address to, uint256 cargoAmountValue);
}