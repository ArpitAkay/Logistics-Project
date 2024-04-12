// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";
import "./Events.sol";
import "./Helpers.sol";
import "./Errors.sol";

contract DisputedServiceRequest {

    // State variables
    Types.ServiceRequestInfo[] internal serviceRequestInfos;

    mapping (string => Types.VoteCount) voteCounts;
    mapping(string => address[]) internal peopleWhoAlreadyVoted;

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

    function vote(string memory _serviceRequestId, Types.WhomToVote whomToVote) external {
        address[] memory addressesOfPeopleWhoAlreadyVoted = peopleWhoAlreadyVoted[_serviceRequestId];
 
        //Checking for people have already voted or not
        for(uint256 i=0; i<addressesOfPeopleWhoAlreadyVoted.length; i++) {
            if(addressesOfPeopleWhoAlreadyVoted[i] == msg.sender) {
                revert Errors.AlreadyVoted({ serviceRequestId: _serviceRequestId,  message: "You have already voted for this service request"});
            }
        }

        Types.ServiceRequestResult memory serviceRequestResult = getServiceRequestById(_serviceRequestId);
        Types.ServiceRequestInfo memory serviceRequestInfo = serviceRequestResult.serviceRequest;
        
        string memory _driverGeoHash = getDriverGeoHash(serviceRequestInfo.driverAssigned);

        if(!Helpers.compareGeoHash(_driverGeoHash, serviceRequestInfo.originLink) || !Helpers.compareGeoHash(_driverGeoHash, serviceRequestInfo.originLink)) {
            revert Errors.ServiceRequestOutOfRegion({ serviceRequestId : _serviceRequestId, message :"Service request not in your region" });
        }

        Types.VoteCount memory voteCount = voteCounts[_serviceRequestId];

        if(voteCount.totalVotesCounted >= 5) {
            if(voteCount.driverVote == voteCount.receiverVote && serviceRequestInfo.shipperAddr == msg.sender) {
                increaseVote(_serviceRequestId, whomToVote);
                peopleWhoAlreadyVoted[_serviceRequestId].push(msg.sender);
                emit Events.VotingMessage(msg.sender, _serviceRequestId, "Voted successfully by shipper");
                return;
            }

            revert Errors.VotingEndedAlready({ serviceRequestId: _serviceRequestId, message: "Voting has already ended"});
        }

        if(msg.sender == serviceRequestInfo.shipperAddr || msg.sender == serviceRequestInfo.receiverAddr || msg.sender == serviceRequestInfo.driverAssigned) {
            revert Errors.SelfVoteNotAllowed({ serviceRequestId: _serviceRequestId, message: "Self vote is not allowed" });
        }

        peopleWhoAlreadyVoted[_serviceRequestId].push(msg.sender);
        increaseVote(_serviceRequestId, whomToVote);

        emit Events.VotingMessage(msg.sender, _serviceRequestId, "Voted successfully");
    }

    function increaseVote(string memory _serviceRequestId, Types.WhomToVote whomToVote) internal {
        if(whomToVote == Types.WhomToVote.Driver)
            voteCounts[_serviceRequestId].driverVote++;
        else
            voteCounts[_serviceRequestId].receiverVote++;
        voteCounts[_serviceRequestId].totalVotesCounted = voteCounts[_serviceRequestId].driverVote + voteCounts[_serviceRequestId].receiverVote;
    }

    function getServiceRequestById(string memory _serviceRequestId) internal view returns (Types.ServiceRequestResult memory) {
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
        string memory _geoHash = getGeoHashOfUser(msg.sender);

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

    function getGeoHashOfUser(address _addr) internal pure returns (string memory) {
        // Get the geohash of user from User contract
        return "";
    }

    function getDriverGeoHash(address _addr) internal pure returns (string memory) {
        return "";
    } 
}