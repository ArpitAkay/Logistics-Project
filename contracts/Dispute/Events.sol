// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";

library Events {
    event OnlyDisputedSRCanBeSaved(address from, Types.ServiceRequestInfo serviceRequestInfo);
    event DisutedSRSaved(address from, string serviceRequestId, Types.ServiceRequestInfo serviceRequestInfo);
    event VotingMessage(address from, string serviceRequestId, string message);
}