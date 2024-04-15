// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";
import "./Events.sol";
import "./Helpers.sol";
import "./Errors.sol";
import "./IUserRoleRequest.sol";

contract DisputedServiceRequest {
    IUserRoleRequest immutable userRoleRequest;

    // State variables
    Types.ServiceRequestInfo[] internal serviceRequestInfos;

    mapping (string => Types.VoteCount) voteCounts;
    mapping(string => address[]) internal peopleWhoAlreadyVoted;

    constructor(address _userRoleRequest) {
        userRoleRequest = IUserRoleRequest(_userRoleRequest);
    }

    modifier isValidUser(address _addr) {
        // Check here address has any role other than None
        userRoleRequest.hasNoneRole(_addr);
        _;
    }

    function saveDisutedServiceRequest(address from, Types.ServiceRequestInfo memory serviceRequestInfo) external {
        if(serviceRequestInfo.status != Types.Status.DISPUTE) {
            emit Events.OnlyDisputedSRCanBeSaved(from, serviceRequestInfo);
            return;
        }

        serviceRequestInfos.push(serviceRequestInfo);
        Types.VoteCount memory voteCount = Types.VoteCount({
            driverVote: 0,
            receiverVote: 0,
            totalVotesCounted: 0
        });

        voteCounts[serviceRequestInfo.serviceRequestId] = voteCount;

        emit Events.DisutedSRSaved(from, serviceRequestInfo.serviceRequestId, serviceRequestInfo);
    }

    function vote(string memory _serviceRequestId, Types.WhomToVote whomToVote) isValidUser(msg.sender) external {
        address[] memory addressesOfPeopleWhoAlreadyVoted = peopleWhoAlreadyVoted[_serviceRequestId];
 
        //Checking for people have already voted or not
        for(uint256 i=0; i<addressesOfPeopleWhoAlreadyVoted.length; i++) {
            if(addressesOfPeopleWhoAlreadyVoted[i] == msg.sender) {
                revert Errors.AlreadyVoted({ serviceRequestId: _serviceRequestId,  message: "You have already voted for this service request"});
            }
        }

        Types.ServiceRequestResult memory serviceRequestResult = getDisputedServiceRequestByIdWithIndex(_serviceRequestId);
        Types.ServiceRequestInfo memory serviceRequestInfo = serviceRequestResult.serviceRequest;
        
        string memory _driverGeoHash = userRoleRequest.getUserGeoHash(serviceRequestInfo.driverAssigned);

        if(!Helpers.compareGeoHash(_driverGeoHash, serviceRequestInfo.originLink) || !Helpers.compareGeoHash(_driverGeoHash, serviceRequestInfo.originLink)) {
            revert Errors.ServiceRequestOutOfRegion({ serviceRequestId : _serviceRequestId, message :"Service request not in your region" });
        }

        Types.VoteCount memory voteCount = voteCounts[_serviceRequestId];

        if(voteCount.totalVotesCounted >= 5) {
            if(voteCount.driverVote == voteCount.receiverVote && serviceRequestInfo.shipperAddr == msg.sender) {
                increaseVote(_serviceRequestId, whomToVote);
                peopleWhoAlreadyVoted[_serviceRequestId].push(msg.sender);
                emit Events.VotingMessage(_serviceRequestId, "Voted successfully by shipper");
                return;
            }

            revert Errors.VotingEndedAlready({ serviceRequestId: _serviceRequestId, message: "Voting has already ended"});
        }

        if(msg.sender == serviceRequestInfo.shipperAddr || msg.sender == serviceRequestInfo.receiverAddr || msg.sender == serviceRequestInfo.driverAssigned) {
            revert Errors.SelfVoteNotAllowed({ serviceRequestId: _serviceRequestId, message: "Self vote is not allowed" });
        }

        peopleWhoAlreadyVoted[_serviceRequestId].push(msg.sender);
        increaseVote(_serviceRequestId, whomToVote);

        emit Events.VotingMessage(_serviceRequestId, "Voted successfully");
    }

    function increaseVote(string memory _serviceRequestId, Types.WhomToVote whomToVote) internal {
        if(whomToVote == Types.WhomToVote.Driver)
            voteCounts[_serviceRequestId].driverVote++;
        else
            voteCounts[_serviceRequestId].receiverVote++;
        voteCounts[_serviceRequestId].totalVotesCounted = voteCounts[_serviceRequestId].driverVote + voteCounts[_serviceRequestId].receiverVote;
    }

    function decideWinner(string memory _serviceRequestId) external returns (Types.ServiceRequestInfo memory){
        Types.ServiceRequestResult memory serviceRequestResult = getDisputedServiceRequestByIdWithIndex(_serviceRequestId);
        Types.ServiceRequestInfo memory serviceRequestInfo = serviceRequestResult.serviceRequest;
        uint256 index = serviceRequestResult.index;

        Types.VoteCount memory voteCount = voteCounts[_serviceRequestId];

        //Checking voting has ended or not
        if(voteCount.totalVotesCounted < 5) {
            revert Errors.VotingInProgress({ from: msg.sender, serviceRequestId: _serviceRequestId, message: "Voting is still in progress" });
        }

        //Deciding the winner
        if(serviceRequestInfo.status == Types.Status.DISPUTE_RESOLVED) {
            emit Events.VotingMessage(_serviceRequestId, serviceRequestInfo.disputeWinner);
        }

        else if(voteCount.driverVote > voteCount.receiverVote) {
            serviceRequestInfos[index].status = Types.Status.DISPUTE_RESOLVED;
            serviceRequestInfos[index].disputeWinner = "Hurray! Driver Wins";

            emit Events.VotingMessage(_serviceRequestId, "Hurray! Driver Wins");
        }
        else if(voteCount.driverVote < voteCount.receiverVote) {
            // call the function of user contract to deduct stars
            userRoleRequest.deductStars(serviceRequestInfo.driverAssigned);        
            serviceRequestInfos[index].status = Types.Status.DISPUTE_RESOLVED;
            serviceRequestInfos[index].disputeWinner = "Hurray! Receiver Wins";

            emit Events.VotingMessage(_serviceRequestId, "Hurray! Receiver Wins");
        } else {
            serviceRequestInfos[index].disputeWinner = "Draw, shipper needs to vote";
            emit Events.VotingMessage(_serviceRequestId, "Draw, shipper needs to vote");
        }

        return serviceRequestInfo;
    }

    function getDisputedServiceRequestByIdWithIndex(string memory _serviceRequestId) internal view returns (Types.ServiceRequestResult memory) {
        Types.ServiceRequestResult memory serviceRequestResult;

        for(uint256 i=0; i<serviceRequestInfos.length; i++) {
            if(Helpers.compareStrings(serviceRequestInfos[i].serviceRequestId, _serviceRequestId)) {
                serviceRequestResult.serviceRequest = serviceRequestInfos[i];
                serviceRequestResult.index = i;
                return serviceRequestResult;
            }
        }

        revert Errors.ServiceRequestDoesNotExists({ serviceRequestId: _serviceRequestId, message: "Service request does not exists"});
    }

    function getAllDisputedServiceRequestInDriverArea() external view returns (Types.ServiceRequestInfo[] memory) {
        string memory _geoHash =  userRoleRequest.getUserGeoHash(msg.sender);

        Types.ServiceRequestInfo[] memory temp = new Types.ServiceRequestInfo[](serviceRequestInfos.length);
        uint256 count = 0;

        for(uint256 i=0; i<serviceRequestInfos.length; i++) {
            Types.ServiceRequestInfo memory request = serviceRequestInfos[i];
            if(Helpers.compareGeoHash(_geoHash, request.originLink) && Helpers.compareGeoHash(_geoHash, request.originLink)) {
                temp[count] = request;
                count++;
            }
        }

        Types.ServiceRequestInfo[] memory allDisputeRequestInDriverArea = new Types.ServiceRequestInfo[](count);

        for(uint256 i=0; i<count; i++) {
            allDisputeRequestInDriverArea[i] = temp[i];
        }

        return allDisputeRequestInDriverArea;
    }
}