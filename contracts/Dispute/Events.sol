// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";

library Events {
    event DisputedSRSaved(address from, string serviceRequestId, Types.ServiceRequestInfo serviceRequestInfo);
    event VotingMessage(string serviceRequestId, string message);
}