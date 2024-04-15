// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Errors {
    error AlreadyVoted(string serviceRequestId, string message);
    error VotingEndedAlready(string serviceRequestId, string message);
    error SelfVoteNotAllowed(string serviceRequestId, string message);
    error ServiceRequestDoesNotExists(string serviceRequestId, string message);
    error ServiceRequestOutOfRegion(string serviceRequestId, string message);
    error VotingInProgress(address from, string serviceRequestId, string message);
}