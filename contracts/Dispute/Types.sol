// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Types {
    enum Status {
        READY_FOR_AUCTION, DRAFT, DRIVER_ASSIGNED, READY_FOR_PICKUP, DRIVER_ARRIVED_AT_ORIGIN, PARCEL_PICKED_UP, OUT_FOR_DELIVERY, DRIVER_ARRIVED_AT_DESTINATION, DELIVERED, DISPUTE, CANCELLED, DISPUTE_RESOLVED
    }

    struct ServiceRequestInfo {
        string serviceRequestId;
        string description;
        address shipperAddr;
        address receiverAddr;
        int256 originLatitude;
        int256 originLongitude;
        int256 destinationLatitude;
        int256 destinationLongitude;
        string originLink;
        string destinationLink;
        uint256 cargoInsurableValue;    // Product Value
        uint256 serviceFee;
        uint256 requestedPickupTime;     // In timestamp
        uint256 requestedDeliveryTime;  // In timestamp
        uint256 auctionTime;
        address driverAssigned;
        Status status;
        string disputeWinner;
    }

    struct VoteCount {
        uint256 driverVote;
        uint256 receiverVote;
        uint256 totalVotesCounted;
    }

    struct ServiceRequestResult {
        Types.ServiceRequestInfo serviceRequest;
        uint256 index;
    }
    
    enum WhomToVote {
        Driver, Receiver
    }
}