// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./Types.sol";
import "./Errors.sol";
import "./Events.sol";
import "./Helpers.sol";
import "./IGeekToken.sol";
import "./IDisputedServiceRequest.sol";
import "./IUserRoleRequest.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ServiceRequest {
    IGeekToken immutable geekToken;
    IDisputedServiceRequest immutable disputedServiceRequest;
    IUserRoleRequest immutable userRoleRequest;

    // State variables
    Types.ServiceRequestInfo[] internal serviceRequestInfos;
    mapping (string => Types.DriverInfoDto) winnerInfo;
    mapping (string => Types.DriverInfoDto[]) peopleWhoAlreadyBidded;

    constructor(address _geekToken, address _disputedServiceRequest, address _userRoleRequest) {
        geekToken = IGeekToken(_geekToken);
        disputedServiceRequest = IDisputedServiceRequest(_disputedServiceRequest);
        userRoleRequest = IUserRoleRequest(_userRoleRequest);
    }

    modifier hasRoleShipperOrAdminAndReceiver(address _shipper, address _receiver) {
        // Check _shipper has role Shipper or Admin
        // Check _receiver has role Receiver
        // Check _shipper and _receiver are not same
        userRoleRequest.hasRoleShipperOrAdminAndReceiver(_shipper, _receiver);
        _;
    }

    modifier hasRoleShipperOrAdmin(address _addr) {
        // Check here address has role Shipper or Admin
        userRoleRequest.hasRoleShipperOrAdmin(_addr);
        _;
    }

    modifier hasRoleDriver(address _addr) {
        // Check here address has role Driver
        userRoleRequest.hasRoleDriver(_addr);
        _;
    }

    modifier isValidUser(address _addr) {
        userRoleRequest.isUserRegistered(_addr);
        _;
    }

    function createServiceRequest(Types.ServiceRequestInfoDto memory _serviceRequestInfoDto) external payable 
    hasRoleShipperOrAdminAndReceiver(msg.sender, _serviceRequestInfoDto.receiverAddr)
    {
        checkValidationsForServiceRequestCreation(_serviceRequestInfoDto, msg.value);

        string memory _serviceRequestId = Helpers.generateRandomString(6);
        Types.ServiceRequestInfo memory serviceRequestInfo = Types.ServiceRequestInfo({
            serviceRequestId: _serviceRequestId,
            description: _serviceRequestInfoDto.description,
            shipperAddr: msg.sender,
            receiverAddr: _serviceRequestInfoDto.receiverAddr,
            originLatitude: _serviceRequestInfoDto.originLatitude,
            originLongitude: _serviceRequestInfoDto.originLongitude,
            destinationLatitude: _serviceRequestInfoDto.destinationLatitude,
            destinationLongitude: _serviceRequestInfoDto.destinationLongitude,
            originLink: _serviceRequestInfoDto.originLink,
            destinationLink: _serviceRequestInfoDto.destinationLink,
            cargoInsurableValue: _serviceRequestInfoDto.cargoInsurableValue * (10 ** 18),
            serviceFee: msg.value,
            requestedPickupTime: _serviceRequestInfoDto.requestedPickupTime,
            requestedDeliveryTime: _serviceRequestInfoDto.requestedDeliveryTime,
            auctionTime: _serviceRequestInfoDto.status == Types.ServiceRequestInitialStatus.READY_FOR_AUCTION ? block.timestamp + (1 minutes * _serviceRequestInfoDto.auctionTime) : _serviceRequestInfoDto.auctionTime,
            driverAssigned: address(0),
            status: _serviceRequestInfoDto.status == Types.ServiceRequestInitialStatus.READY_FOR_AUCTION ? Types.Status.READY_FOR_AUCTION : Types.Status.DRAFT,
            disputeWinner: ""
        });

        // Adding newly created service request in serviceRequestInfos
        serviceRequestInfos.push(serviceRequestInfo);

        Types.DriverInfoDto memory driverWinnerInfo = Types.DriverInfoDto({
            driverAddress: address(0),
            serviceFee: msg.value + 1,
            cargoInsuranceValue: _serviceRequestInfoDto.cargoInsurableValue * (10 ** 18),
            cargoValueRefunded: false,
            serviceFeeRefunded: false
        });

        winnerInfo[_serviceRequestId] = driverWinnerInfo;

        emit Events.ServiceRequestCreated(serviceRequestInfo, msg.sender, "Service Request created successfully");
    }

    // Function for validation check for inputs of service request
    function checkValidationsForServiceRequestCreation(Types.ServiceRequestInfoDto memory _serviceRequestInfoDto, uint256 _serviceFee) internal view {
        // Validation check for description of product to deliver
        if(bytes(_serviceRequestInfoDto.description).length == 0) {
            revert Errors.InvalidDescription({ description: _serviceRequestInfoDto.description, message: "Description value cannot be empty"});
        }

        // Validation check for origin latitude, longitude and destination latitude, longitude of product to deliver
        checkValidGpsCoordinates(_serviceRequestInfoDto.originLatitude, _serviceRequestInfoDto.originLongitude);
        checkValidGpsCoordinates(_serviceRequestInfoDto.destinationLatitude, _serviceRequestInfoDto.destinationLongitude);

        // Checking geoHash is provided or not
        // Compare with geoHash of Shipper
        checkValidGeoHash(_serviceRequestInfoDto.originLink);
        checkValidGeoHash(_serviceRequestInfoDto.destinationLink);

        // Checking cargo insurable value is provided or not
        if(_serviceRequestInfoDto.cargoInsurableValue <= 0) {
            revert Errors.InvalidProductValue({ value: _serviceRequestInfoDto.cargoInsurableValue, message: "Cargo insurance value cannot be less than or equal to zero"});
        }

        // Checking service fee is provided or not
        if(_serviceFee <= 0) {
            revert Errors.InvalidProductValue({ value: _serviceFee, message: "Service value cannot be less than or equal to zero"});
        }

        // Checking pick up time, delivery time and auction time are valid or not
        checkValidTimmings(_serviceRequestInfoDto.requestedPickupTime, _serviceRequestInfoDto.requestedDeliveryTime, _serviceRequestInfoDto.auctionTime);
    }

    // Function for validation of gps coordinates
    function checkValidGpsCoordinates(int256 _latitude, int256 _longitude) internal pure {
        // Checking valid latitude and longitude
        if(_latitude < -90 * (10 ** 16) ||  _latitude > 90 * (10 ** 16)) {
            revert Errors.InvalidCoordinates({ latitude: _latitude, longitude: _longitude, message: "Enter valid latitude coordinates"});
        }
        if(_longitude < -180 * (10 ** 16) || _longitude > 180 * (10 ** 16)) {
            revert Errors.InvalidCoordinates({ latitude: _latitude, longitude: _longitude, message: "Enter valid longitude coordinates"});
        }
    }

    // Function for validation of geohash
    function checkValidGeoHash(string memory _geoHash) internal pure {
        // Checking geoHash is provided or not
        if(bytes(_geoHash).length == 0) {
            revert Errors.InvalidGeoHash({geoHash: _geoHash, message: "GeoHash cannot be empty"});
        }
    }

    // Function for validation of pickup time, delivery time and auction time
    function checkValidTimmings(uint256 _reqestedPickupTime, uint256 _requestedDeliveryTime, uint256 _auctionStartTime) internal view {
        // Checking auction start time has been provided or not
        if(_auctionStartTime <= 0) {
            revert Errors.InvalidTimmings({ timestamp: _auctionStartTime, message: "Auction time cannot be less than or equal to zero"});
        }

        // Checking requested pickup time is in the future
        if(_reqestedPickupTime <= block.timestamp) {
            revert Errors.InvalidTimmings({ timestamp: _reqestedPickupTime, message: "Request pickup time must be in the future"});
        }

        // Checking requested delivery time is in the future
        if(_requestedDeliveryTime <= block.timestamp) {
            revert Errors.InvalidTimmings({ timestamp: _requestedDeliveryTime, message: "Request delivery time must be in the future"});
        }
        
        // Checking if requested delivery time is after requested pickup time
        if (_requestedDeliveryTime <= _reqestedPickupTime) {
            revert Errors.InvalidTimmings({ timestamp: _requestedDeliveryTime, message: "Requested delivery time must be after requested pickup time"});
        }  
    }

    // Function for updating drafted service request
    function updateDraftedServiceRequest(string memory _serviceRequestId) external hasRoleShipperOrAdmin(msg.sender) {
        // Getting ServiceRequestInfo and index of it by _serviceRequestId
        Types.ServiceRequestResult memory serviceRequestResult = getServiceRequestById(_serviceRequestId);
        Types.ServiceRequestInfo memory serviceRequestInfo = serviceRequestResult.serviceRequest;
        uint256 index = serviceRequestResult.index;

        if(serviceRequestInfo.status != Types.Status.DRAFT) {
            revert Errors.SRCannotBeUpdated({ serviceRequestId: _serviceRequestId, message: "Service Request is not in DRAFT status"});
        }

        if(!userRoleRequest.isAdmin(msg.sender)) {
            if(serviceRequestInfo.shipperAddr != msg.sender) {
                revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "You are not the shipper of this service request"});
            }
        }

        serviceRequestInfos[index].auctionTime = block.timestamp +  (serviceRequestInfos[index].auctionTime * 1 minutes);
        serviceRequestInfos[index].status = Types.Status.READY_FOR_AUCTION;

        emit Events.ServiceRequestUpdated(serviceRequestInfos[index], msg.sender, "Service request updated successfully to READY_FOR_AUCTION");
        
    }

    // Function for bidding (Dutch bidding - One person can vote for only time)
    function dutchBid(string memory _serviceRequestId, uint256 _serviceFee) external hasRoleDriver(msg.sender) payable {
        // Getting ServiceRequestInfo and index of it by _serviceRequestId
        Types.ServiceRequestResult memory serviceRequestResult = getServiceRequestById(_serviceRequestId);
        Types.ServiceRequestInfo memory serviceRequestInfo = serviceRequestResult.serviceRequest;

        // Checking bidding start time i.e auctionStartTime started or not
        if(serviceRequestInfo.status != Types.Status.READY_FOR_AUCTION) {
            revert Errors.AuctionNotStarted({ serviceRequestId: _serviceRequestId, message: "Service request is not ready for auction yet"});
        }

        // Checking auction has already ended or not
        if(block.timestamp >= serviceRequestInfo.auctionTime) {
            revert Errors.AuctionEnded({ serviceRequestId: _serviceRequestId, message: "Auction for service request has ended already"});
        }

        string memory _driverGeoHash = userRoleRequest.getUserGeoHash(msg.sender);

        // Comparing geohash of originLink and destinationLink with driverGeoHash
        if(!Helpers.compareGeoHash(_driverGeoHash, serviceRequestInfo.originLink) || !Helpers.compareGeoHash(_driverGeoHash, serviceRequestInfo.destinationLink)) {
            revert Errors.ServiceRequestOutOfRegion({ serviceRequestId: _serviceRequestId, message: "Service request is not in your region"});
        }

        // Checking msg.value is equal to cargo insurable value
        if(msg.value != serviceRequestInfo.cargoInsurableValue) {
            revert Errors.InvalidCargoInsuranceValue({ cargoInsuranceValue: msg.value, message: "Cargo insurable value should be equal to Product value"});
        }

        // Checking service fee with cargo insurable value
        if(_serviceFee <= 0 || _serviceFee  > serviceRequestInfo.serviceFee) {
            revert Errors.InvalidServiceFee({ serviceFee: _serviceFee, message: "Service Fee should be less than or equal to the service fee provide by shipper"});
        }

        // Getting address of people who already voted so to avoid re voting
        Types.DriverInfoDto[] memory driverInfosWhoHasAlreadyBidded = peopleWhoAlreadyBidded[_serviceRequestId];

        // Check Already bidded for the service request
        checkAlreadyBidded(msg.sender, driverInfosWhoHasAlreadyBidded);

        // Storing bidder address in array of people who already voted
        Types.DriverInfoDto memory driverInfoWhoBidded = Types.DriverInfoDto({
                driverAddress: msg.sender,
                serviceFee: _serviceFee,
                cargoInsuranceValue: msg.value,
                cargoValueRefunded: false,
                serviceFeeRefunded: false
        });

        peopleWhoAlreadyBidded[_serviceRequestId].push(driverInfoWhoBidded);

        if(_serviceFee < winnerInfo[_serviceRequestId].serviceFee) {
            winnerInfo[_serviceRequestId] = driverInfoWhoBidded;
        }

        emit Events.BiddedSuccessfully(_serviceRequestId, msg.sender, _serviceFee);
    }

    // Check function for person has already bidded or not
    function checkAlreadyBidded(address _bidder, Types.DriverInfoDto[] memory _driverInfosWhoHasAlreadyBidded) internal pure {
        for(uint256 i=0; i<_driverInfosWhoHasAlreadyBidded.length; i++) {
            if(_driverInfosWhoHasAlreadyBidded[i].driverAddress == _bidder) {
                revert Errors.AlreadyBidded({ bidder: _bidder, message: "You have already bidded for this service request"});
            }
        }
    }

    // Cancel service request
    function cancelServiceRequest(string memory _serviceRequestId) external {
        Types.ServiceRequestResult memory serviceRequestResult = getServiceRequestById(_serviceRequestId);
        Types.ServiceRequestInfo memory serviceRequestInfo = serviceRequestResult.serviceRequest;
        uint256 index = serviceRequestResult.index;

        if(serviceRequestInfo.status == Types.Status.CANCELLED) {
            revert Errors.ServiceRequestCannotBeCancelled({ serviceRequestId: _serviceRequestId, message: "Service request is already cancelled"});
        }

        // Checking status of service request for Draft / Ready for Auction / In Auction
        if(serviceRequestInfo.status == Types.Status.DRAFT || serviceRequestInfo.status == Types.Status.READY_FOR_AUCTION) {
            
            // Only Shipper or Admin can cancel the service request 
            if(!userRoleRequest.isAdmin(msg.sender)) {
                if(msg.sender != serviceRequestInfo.shipperAddr) {
                    revert Errors.ServiceRequestCannotBeCancelled({ serviceRequestId: _serviceRequestId, message: "Only shipper can cancelled the service request"});
                }
            }

            if(serviceRequestInfo.driverAssigned != address(0)) {
                if(block.timestamp >= serviceRequestInfo.auctionTime)
                    serviceRequestInfos[index].status = Types.Status.DRIVER_ASSIGNED;
                revert Errors.ServiceRequestCannotBeCancelled({ serviceRequestId: _serviceRequestId, message: "Service request cannot be cancelled, as driver is already assigned"});
            }

            // Cancelling service request
            serviceRequestInfos[index].status = Types.Status.CANCELLED;
            payable(serviceRequestInfo.shipperAddr).transfer(serviceRequestInfo.serviceFee);

            emit Events.ServiceRequestCancelled(_serviceRequestId, msg.sender);
        } else {
            revert Errors.ServiceRequestCannotBeCancelled({ serviceRequestId: _serviceRequestId, message: "Service request cannot be cancelled as service request is not DRAFT OR READY_FOR_AUCTION status"});
        }
    }

    // Decide winner of auction by shipper or admin only
    function declareWinner(string memory _serviceRequestId) external {
        Types.ServiceRequestResult memory serviceRequestResult = getServiceRequestById(_serviceRequestId);
        Types.ServiceRequestInfo memory serviceRequestInfo = serviceRequestResult.serviceRequest;
        uint256 index = serviceRequestResult.index;

        if(serviceRequestInfo.status == Types.Status.DRIVER_ASSIGNED) {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Winner already declared, driver is already assigned to service request"});
        }

        if(serviceRequestInfo.status == Types.Status.CANCELLED) {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Service request is already cancelled, cannot decide winner"});
        }
        
        if(block.timestamp <= serviceRequestInfo.auctionTime) {
            revert Errors.AuctionInProgress({ serviceRequestId: _serviceRequestId, message: "Auction still inprogress"});
        }

        if(msg.sender != serviceRequestInfo.shipperAddr && !userRoleRequest.isAdmin(msg.sender)) {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "You need to be shipper of this service request or have ADMIN role"});
        }

        Types.DriverInfoDto memory driverWinnerInfo = winnerInfo[_serviceRequestId];

        if(driverWinnerInfo.driverAddress == address(0)) {
            serviceRequestInfos[index].auctionTime = block.timestamp + 5 minutes;

            emit Events.IncreasedAuctionTimeForSR(_serviceRequestId, msg.sender, "Increased auction time for service request by 5 minutes");
        }  else {
            serviceRequestInfos[index].status = Types.Status.DRIVER_ASSIGNED;
            serviceRequestInfos[index].driverAssigned = driverWinnerInfo.driverAddress;

            refundCargoValueToDriversExceptWinner(_serviceRequestId, driverWinnerInfo.driverAddress);

            emit Events.AuctionResult(_serviceRequestId, msg.sender, string(abi.encodePacked(abi.encodePacked(driverWinnerInfo.driverAddress), " ", "You have won the auction")));
        }
    }

    // Refund cargo insurance value to driver except winner
    function refundCargoValueToDriversExceptWinner(string memory _serviceRequestId, address _winnerAddress) internal {
        Types.DriverInfoDto[] memory driverWhoBiddedForServiceRequest = peopleWhoAlreadyBidded[_serviceRequestId];

        for(uint256 i=0; i<driverWhoBiddedForServiceRequest.length; i++) {
            if(!driverWhoBiddedForServiceRequest[i].cargoValueRefunded && driverWhoBiddedForServiceRequest[i].driverAddress != _winnerAddress) {
                uint256 cargoValue = driverWhoBiddedForServiceRequest[i].cargoInsuranceValue;
                if(address(this).balance >= cargoValue) {
                    peopleWhoAlreadyBidded[_serviceRequestId][i].cargoValueRefunded = true;
                    payable(driverWhoBiddedForServiceRequest[i].driverAddress).transfer(driverWhoBiddedForServiceRequest[i].cargoInsuranceValue);
                }
            }
        }
    }

    // check winner of auction by bidded drivers only
    function checkWinner(string memory _serviceRequestId) external view isValidUser(msg.sender) returns (Types.DriverInfoDto memory) {
        Types.ServiceRequestResult memory serviceRequestResult = getServiceRequestById(_serviceRequestId);
        Types.ServiceRequestInfo memory serviceRequestInfo = serviceRequestResult.serviceRequest;

        if(serviceRequestInfo.status == Types.Status.CANCELLED) {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Service request is already cancelled, cannot decide winner"});
        }
        
        if(block.timestamp <= serviceRequestInfo.auctionTime) {
            revert Errors.AuctionInProgress({ serviceRequestId: _serviceRequestId, message: "Auction still inprogress"});
        }

        if(serviceRequestInfo.status == Types.Status.READY_FOR_AUCTION) {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Winner yet to be declared"});
        }

        return winnerInfo[_serviceRequestId];
    }

    // Status update of service request by shipper
    function updateServiceRequestStatusByShipper(string memory _serviceRequestId, Types.Status _status) external {
        Types.ServiceRequestResult memory serviceRequestResult = getServiceRequestById(_serviceRequestId);
        Types.ServiceRequestInfo memory serviceRequestInfo = serviceRequestResult.serviceRequest;
        uint256 index = serviceRequestResult.index;

        if(serviceRequestInfo.status == Types.Status.CANCELLED) {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Service request is already cancelled"});
        } 

        if(msg.sender != serviceRequestInfo.shipperAddr) {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Only shipper can update the status"});
        }
        
        if(_status == Types.Status.READY_FOR_PICKUP && serviceRequestInfo.status == Types.Status.DRIVER_ASSIGNED) {
            serviceRequestInfos[index].status = _status;
            emit Events.UpdatedSRStatus(_serviceRequestId, msg.sender, "Updated service request successfully to READY_FOR_PICKUP");
        } else {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "The status you sent cannot be updated at this point"});
        }
    }

    // Status update of service request by driver
    function updateServiceRequestStatusByDriver(string memory _serviceRequestId, Types.Status _status) external {
        Types.ServiceRequestResult memory serviceRequestResult = getServiceRequestById(_serviceRequestId);
        Types.ServiceRequestInfo memory serviceRequestInfo = serviceRequestResult.serviceRequest;
        uint256 index = serviceRequestResult.index;

        if(serviceRequestInfo.status == Types.Status.CANCELLED) {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Service request is already cancelled"});
        }

        if(msg.sender != serviceRequestInfo.driverAssigned) {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Only assigned driver can update the status"});
        }

        if(_status == Types.Status.DRIVER_ARRIVED_AT_ORIGIN || _status == Types.Status.PARCEL_PICKED_UP || _status == Types.Status.OUT_FOR_DELIVERY || _status == Types.Status.DRIVER_ARRIVED_AT_DESTINATION) {
            if(serviceRequestInfo.status == Types.Status.READY_FOR_PICKUP) {
                if(_status == Types.Status.DRIVER_ARRIVED_AT_ORIGIN) {
                    serviceRequestInfos[index].status = _status;
                    emit Events.UpdatedSRStatus(_serviceRequestId, msg.sender, "Updated service request successfully to DRIVER_ARRIVED_AT_ORIGIN");
                } else {
                    revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "The status you sent cannot be updated at this point"});
                }
            } else if(serviceRequestInfo.status == Types.Status.DRIVER_ARRIVED_AT_ORIGIN) {
                if(_status == Types.Status.PARCEL_PICKED_UP) {
                    serviceRequestInfos[index].status = _status;
                    emit Events.UpdatedSRStatus(_serviceRequestId, msg.sender, "Updated service request successfully to PARCEL_PICKED_UP");
                } else {
                    revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "The status you sent cannot be updated at this point"});
                }
            } else if(serviceRequestInfo.status == Types.Status.PARCEL_PICKED_UP) {
                if(_status == Types.Status.OUT_FOR_DELIVERY) {
                    serviceRequestInfos[index].status = _status;
                    emit Events.UpdatedSRStatus(_serviceRequestId, msg.sender, "Updated service request successfully to OUT_FOR_DELIVERY");
                } else {
                    revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "The status you sent cannot be updated at this point"});
                }
            } else if(serviceRequestInfo.status == Types.Status.OUT_FOR_DELIVERY) {
                if(_status == Types.Status.DRIVER_ARRIVED_AT_DESTINATION) {
                    serviceRequestInfos[index].status = _status;
                    emit Events.UpdatedSRStatus(_serviceRequestId, msg.sender, "Updated service request successfully to DRIVER_ARRIVED_AT_DESTINATION");
                } else {
                    revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "The status you sent cannot be updated at this point"});
                }
            } else {
                revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "The status you sent cannot be updated at this point"});
            }
        } else {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "You don't have the access to the update the status"});
        }
    }

    // Status update of service request by receiver
    function updateServiceRequestStatusByReceiver(string memory _serviceRequestId, Types.Status _status, Types.Acceptance acceptance) external {
        Types.ServiceRequestResult memory serviceRequestResult = getServiceRequestById(_serviceRequestId);
        Types.ServiceRequestInfo memory serviceRequestInfo = serviceRequestResult.serviceRequest;
        uint256 index = serviceRequestResult.index;

        if(serviceRequestInfo.status == Types.Status.DISPUTE) {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Service request is in dispute state"});
        }

        if(serviceRequestInfo.status == Types.Status.CANCELLED) {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Service request is already cancelled"});
        }

        if(msg.sender != serviceRequestInfo.receiverAddr) {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Only receiver can update the status"});
        }  
        
        if(_status == Types.Status.DELIVERED) {
            if(serviceRequestInfo.status != Types.Status.DRIVER_ARRIVED_AT_DESTINATION) {
                revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Driver has not reached at destination yet, cannot update status to DELIVERED"});
            }
            
            if(acceptance == Types.Acceptance.CONDITIONAL) {
                serviceRequestInfos[index].status = _status;
                refundCargoValueToWinnerDriver(_serviceRequestId);
                refundAndGiveServiceFeeToShipperAndWinnerDriver(serviceRequestInfo);
                geekToken.transferTokens(serviceRequestInfo.driverAssigned, serviceRequestInfo.cargoInsurableValue, Types.Acceptance.CONDITIONAL);

                emit Events.UpdatedSRStatus(_serviceRequestId, msg.sender, "Updated service request successfully to DELIVERED-CONDITIONAL");
            } else {
                serviceRequestInfos[index].status = Types.Status.DISPUTE;
                serviceRequestInfo.status = Types.Status.DISPUTE;

                // send service request to dispute contract
                disputedServiceRequest.saveDisputedServiceRequest(address(this), serviceRequestInfo);
                geekToken.transferTokens(serviceRequestInfo.driverAssigned, serviceRequestInfo.cargoInsurableValue, Types.Acceptance.UNCONDITIONAL);

                emit Events.UpdatedSRStatus(_serviceRequestId, msg.sender, "Updated service request successfully to DELIVERED-UNCONDITIONAL");
            }
        } else {
            revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Receiver can only update status : DELIVERED"});
        }
    }

    // Refund cargo insurance value to winner driver
    function refundCargoValueToWinnerDriver(string memory _serviceRequestId) internal {
        Types.DriverInfoDto memory winnerDriverInfo = winnerInfo[_serviceRequestId];

        if(!winnerDriverInfo.cargoValueRefunded) {
            if(address(this).balance >= winnerDriverInfo.cargoInsuranceValue) {
                winnerInfo[_serviceRequestId].cargoValueRefunded = true;
                payable(winnerDriverInfo.driverAddress).transfer(winnerDriverInfo.cargoInsuranceValue);
            }
        }
    }

    function refundAndGiveServiceFeeToShipperAndWinnerDriver(Types.ServiceRequestInfo memory serviceRequestInfo) internal {
        Types.DriverInfoDto memory winnerDriverInfo = winnerInfo[serviceRequestInfo.serviceRequestId];

        if(address(this).balance >= serviceRequestInfo.serviceFee) {
            winnerInfo[serviceRequestInfo.serviceRequestId].serviceFeeRefunded = true;
            payable(winnerDriverInfo.driverAddress).transfer(winnerDriverInfo.serviceFee);
            payable(serviceRequestInfo.shipperAddr).transfer(serviceRequestInfo.serviceFee - winnerDriverInfo.serviceFee);
        }
    }

    function refundCargoValueToReceiver(address _receiverAddr, uint256 _cargoValue) internal {
        if(address(this).balance >= _cargoValue) {
            payable(_receiverAddr).transfer(_cargoValue);
        }
    } 

    // Retrieving all service request in driver's geo hash
    function getAllServiceRequestInfosInGeoHash(string memory _geoHash) external view hasRoleDriver(msg.sender) returns (Types.ServiceRequestInfo[] memory) {
        Types.ServiceRequestInfo[] memory tempList = new Types.ServiceRequestInfo[](serviceRequestInfos.length);
        uint256 count = 0;

        for(uint256 i=0; i<serviceRequestInfos.length; i++) {
            Types.ServiceRequestInfo memory request = serviceRequestInfos[i];

            // Checking service requests are in auction and originLink & destinationLink are in geohash of driver
            if(request.status == Types.Status.READY_FOR_AUCTION && Helpers.compareGeoHash(_geoHash, request.originLink) && Helpers.compareGeoHash(_geoHash, request.destinationLink)) {
                tempList[count] = request;
                count++;
            }
        }

        Types.ServiceRequestInfo[] memory allServiceRequestInfoWithStatusInAuction = new Types.ServiceRequestInfo[](count);
        for(uint256 i=0; i<count; i++) {
            allServiceRequestInfoWithStatusInAuction[i] = tempList[i];
        }

        return allServiceRequestInfoWithStatusInAuction;
    }

    // Get info of service request by id
    function getServiceRequestInfoById(string memory _serviceRequestId) external view returns (Types.ServiceRequestInfo memory) {
        Types.ServiceRequestResult memory _serviceRequestResult = getServiceRequestById(_serviceRequestId);
        Types.ServiceRequestInfo memory _serviceRequestInfo = _serviceRequestResult.serviceRequest;

        address _addr = msg.sender;
        if(_addr == _serviceRequestInfo.shipperAddr || _addr == _serviceRequestInfo.receiverAddr || _addr == _serviceRequestInfo.driverAssigned || userRoleRequest.isAdmin(_addr)) {
            return _serviceRequestInfo;
        } 
        
        revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "You don't have access to view service request info"});
    }

    // Get All the service request that user was involved
    function getAllServiceRequestOfUser() external view returns (Types.ServiceRequestInfo[] memory) {
        address _addr = msg.sender;
        Types.ServiceRequestInfo[] memory tempArray = new Types.ServiceRequestInfo[](serviceRequestInfos.length);
        uint256 count = 0;

        for (uint256 i = 0; i < serviceRequestInfos.length; i++) {
            Types.ServiceRequestInfo memory request = serviceRequestInfos[i];
            if (request.shipperAddr == _addr || request.receiverAddr == _addr || request.driverAssigned == _addr) {
                tempArray[count] = request;
                count++;
            }
        }

        // Resize the temporary array to fit only the necessary elements
        Types.ServiceRequestInfo[] memory allServiceRequestInfoOfUser = new Types.ServiceRequestInfo[](count);
        for (uint256 j = 0; j < count; j++) {
            allServiceRequestInfoOfUser[j] = tempArray[j];
        }

        return allServiceRequestInfoOfUser;
    }

    // Get service request from serviceRequestInfos by serviceRequestId
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

    function decideWinnerForDispute(string memory _serviceRequestId) external {
        Types.ServiceRequestResult memory serviceRequestResult = getServiceRequestById(_serviceRequestId);
        Types.ServiceRequestInfo memory request = serviceRequestResult.serviceRequest;
        uint256 index = serviceRequestResult.index;

        if(request.status == Types.Status.DISPUTE_RESOLVED) {
            revert Errors.SRDisputeAlreadyResolved({ serviceRequestId: _serviceRequestId, message: "Dispute on this service request is already resolved"});
        }

        if(!userRoleRequest.isAdmin(msg.sender)) {
            if(msg.sender != request.shipperAddr && msg.sender != request.receiverAddr && msg.sender != request.driverAssigned) {
                revert Errors.AccessDenied({ serviceRequestId: _serviceRequestId, message: "Only shipper, receiver or driver of this service request can decide winner for dispute request"});
            }
        }

        Types.ServiceRequestInfo memory serviceRequestInfo = disputedServiceRequest.decideWinner(_serviceRequestId);

        serviceRequestInfos[index].status = serviceRequestInfo.status;
        serviceRequestInfos[index].disputeWinner = serviceRequestInfo.disputeWinner;

        if(Helpers.compareStrings(serviceRequestInfo.disputeWinner, "DRIVER")) {
            refundCargoValueToWinnerDriver(request.serviceRequestId);
            refundAndGiveServiceFeeToShipperAndWinnerDriver(serviceRequestInfo);

            emit Events.DisputedSRResult(_serviceRequestId, "Driver has won");
        } else if(Helpers.compareStrings(serviceRequestInfo.disputeWinner, "RECEIVER")) {
            refundCargoValueToReceiver(serviceRequestInfo.receiverAddr, serviceRequestInfo.cargoInsurableValue);
            refundAndGiveServiceFeeToShipperAndWinnerDriver(serviceRequestInfo);

            emit Events.DisputedSRResult(_serviceRequestId, "Receiver has won");
        } else {
            emit Events.DisputedSRResult(_serviceRequestId, "Draw, Shipper has special access to vote for breaking the tie");
        }
    } 
}