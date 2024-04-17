// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Errors {
    error InvalidDescription(string description, string message);
    error InvalidCoordinates(int256 latitude, int256 longitude, string message);
    error InvalidGeoHash(string geoHash, string message);
    error InvalidProductValue(uint256 value, string message);
    error InvalidTimmings(uint256 timestamp, string message);
    error SRCannotBeUpdated(string serviceRequestId, string message);
    error ServiceRequestDoesNotExists(string serviceRequestId, string message);
    error AuctionNotStarted(string serviceRequestId, string message);
    error AuctionEnded(string serviceRequestId, string message);
    error ServiceRequestOutOfRegion(string serviceRequestId, string message);
    error InvalidCargoInsuranceValue(uint256 cargoInsuranceValue, string message);
    error InvalidServiceFee(uint256 serviceFee, string message);
    error AlreadyBidded(address bidder, string message);
    error ServiceRequestCannotBeCancelled(string serviceRequestId, string message);
    error AccessDenied(string serviceRequestId, string message);
    error AuctionInProgress(string serviceRequestId, string message);
    error SRDisputeAlreadyResolved(string serviceRequestId, string message);
}