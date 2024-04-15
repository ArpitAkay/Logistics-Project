// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Types.sol";
import "./Errors.sol";
import "./Events.sol";
import "./IDrivingLicenseNFT.sol";


contract UserRoleRequest is Ownable{

    IDrivingLicenseNFT immutable drivingLicenseNFT;

    Types.RoleRequest[] internal roleRequests;
    mapping(address => Types.User) public users;

    constructor(address initialOwner, address drivingLicenseNFTAddress) 
    Ownable(initialOwner) 
    {
        drivingLicenseNFT = IDrivingLicenseNFT(drivingLicenseNFTAddress);
        Types.Role[] memory adminRole = new Types.Role[](1);
        adminRole[0] = Types.Role.Admin;

        Types.User memory admin = Types.User({
            userName: "Admin",
            userAddress: initialOwner,
            role: adminRole,
            geoHash: "",
            starsInInt: 50,
            starsInString: "50"
        });

        users[initialOwner] = admin;
    }

    function generateRandomString(uint256 length) public view returns (string memory) {
        bytes memory characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        bytes memory randomString = new bytes(length);
        uint256 charLength = characters.length;

        for (uint256 i = 0; i < length; i++) {
            uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number), i))) % charLength;
            randomString[i] = characters[rand];
        }
        return string(randomString);
    }

    modifier checkUserExists(){
        if(users[msg.sender].userAddress == address(0)){
            revert Errors.UserNotRegistered({
                userAddress: msg.sender,
                errMsg: "User is not registered"
            });
        }
        _;
    }

    modifier checkValidInput(string memory _userName, string memory _geoHash){
        if(bytes(_userName).length <= 0){
            revert Errors.InvalidInput({
                userAddress: msg.sender,
                errMsg: "Username required"
            });
        }
        
        if(bytes(_geoHash).length <= 0){
            revert Errors.InvalidInput({
                userAddress: msg.sender,
                errMsg: "GeoHash required"
            });
        }
        _;
    }

    modifier checkUserAlreadyExist() {
        if(users[msg.sender].userAddress != address(0)){
            revert Errors.UserAlreadyExists({userAddress : msg.sender, errMsg :"User already exists"});
        }
        _;
    }

    modifier checkRoleRequest(Types.Role _requestedRole) {
        Types.Role[] memory userRoles = users[msg.sender].role;
        for(uint i=0; i< userRoles.length; i++) {
            if(userRoles[i] == _requestedRole){
                revert Errors.InvalidInput({
                    userAddress: msg.sender,
                    errMsg: "You already have that role"
                });
            }
        }

        if(_requestedRole == Types.Role.None){
            revert Errors.InvalidInput({
                userAddress: msg.sender,
                errMsg: "Cannot request none role"
            });
        }
        
        // Need to validate Driving License NFT
        if(_requestedRole == Types.Role.Driver){
            if(!drivingLicenseNFT.validateNFT(msg.sender)){
                revert Errors.NFTNotFound({userAddress : msg.sender, errMsg :"No Driving License NFT found"});
            }
        }
        _;
    }

    function createUser(string memory _userName, string memory _geoHash) public checkValidInput(_userName,_geoHash) checkUserAlreadyExist {
        Types.Role[] memory noneRole = new Types.Role[](1);
        noneRole[0] = Types.Role.None;


        Types.User memory newUser = Types.User({
            userName: _userName,
            userAddress: msg.sender,
            role: noneRole,
            geoHash: _geoHash,
            starsInInt: 50,
            starsInString: "50"
        });

        users[msg.sender] = newUser;

        emit Events.NewUserCreated(_userName, msg.sender, _geoHash);
    }

    function createRoleRequest(Types.Role _requestedRole) public checkUserExists checkRoleRequest(_requestedRole) {
        string memory _requestId = generateRandomString(4);

        Types.RoleRequest memory newRoleRequest = Types.RoleRequest({
            requestId: _requestId,
            applicantAddress: msg.sender,
            requestedRole: _requestedRole,
            requestStatus: Types.RequestStatus.Pending,
            approverAddress: address(0)
        });

        roleRequests.push(newRoleRequest);

        emit Events.NewRoleRequestCreated(_requestId, msg.sender, _requestedRole);
    }

    function getRoleRequests() public view returns(Types.RoleRequest[] memory){
        return roleRequests;
    }

    function getRoleRequestByIdWithIndex(string memory _roleRequestId) public view returns(Types.RoleRequestWithIndexDto memory) {

        for(uint i=0; i<roleRequests.length; i++){
            if(keccak256(bytes(roleRequests[i].requestId)) == keccak256(bytes(_roleRequestId))){
                return Types.RoleRequestWithIndexDto({roleRequest:roleRequests[i], index: i});
            }
        }
      
        revert Errors.RoleRequestNotFound({
            userAddress: msg.sender,
            errMsg: "Role Request not found",
            requestId: _roleRequestId
        });
       
    }

    function approveOrRejectRoleRequest(string memory _roleRequestId, bool approve) public {
        Types.Role[] memory approverRoles = users[msg.sender].role;

        Types.RoleRequestWithIndexDto memory roleRequestWithIndex = getRoleRequestByIdWithIndex(_roleRequestId);

        Types.RoleRequest memory roleRequest = roleRequestWithIndex.roleRequest;

        if(!isApproverHavingPermission(approverRoles, roleRequest)) {
            revert Errors.NotAuthorized({
                userAddress: msg.sender,
                errMsg: "You don't have permission to approve this request"
            });
        }

        checkRoleRequestStatus(roleRequest); // Checking for already approved or rejected request

        if(approve){
            roleRequest.requestStatus = Types.RequestStatus.Approved;
            roleRequest.approverAddress = msg.sender;

            roleRequests[roleRequestWithIndex.index] = roleRequest;

            addRoleToUser(roleRequest);
        }

        if(!approve) {
            roleRequest.requestStatus = Types.RequestStatus.Rejected;
            roleRequests[roleRequestWithIndex.index] = roleRequest;
        }


    }

    function addRoleToUser(Types.RoleRequest memory roleRequest) internal {
        Types.User memory user = users[roleRequest.applicantAddress];

        Types.Role[] memory userRoles = user.role;

        if(userRoles.length == 1 && userRoles[0] == Types.Role.None){
            Types.Role[] memory updatedRoles = new Types.Role[](1);
            updatedRoles[0] = roleRequest.requestedRole;
            user.role = updatedRoles;
            users[roleRequest.applicantAddress] = user;
        } else {
            Types.Role[] memory updatedRoles = new Types.Role[](user.role.length + 1);
            
            
            for (uint i = 0; i < user.role.length; i++) {
                updatedRoles[i] = user.role[i];
            }
            
            updatedRoles[user.role.length] = roleRequest.requestedRole;
            
            user.role = updatedRoles;
            users[roleRequest.applicantAddress] = user;
        }
    }

    function checkRoleRequestStatus(Types.RoleRequest memory roleRequest) internal view {
        if(roleRequest.requestStatus == Types.RequestStatus.Approved) {
            revert Errors.AlreadyProcessedError({
                userAddress: msg.sender,
                errMsg: "Role request already approved",
                requestId: roleRequest.requestId
            });
        }

        if(roleRequest.requestStatus == Types.RequestStatus.Rejected) {
            revert Errors.AlreadyProcessedError({
                userAddress: msg.sender,
                errMsg: "Role request already rejected",
                requestId: roleRequest.requestId
            });
        }
    }

    function isApproverHavingPermission(Types.Role[] memory approverRoles,Types.RoleRequest memory roleRequest) internal view returns (bool) {
        if(msg.sender == roleRequest.applicantAddress) {
            revert Errors.NotAuthorized({userAddress:msg.sender,errMsg:"Self approve or reject is not allowed"});
        }

        Types.Role requestedRole = roleRequest.requestedRole;

        if(requestedRole == Types.Role.Admin) {
            for(uint i=0; i<approverRoles.length; i++){
                if(approverRoles[i] == Types.Role.Admin) {
                    return true;
                }
            }
            return false;
        }

        if(requestedRole == Types.Role.Shipper) {
            for(uint i=0; i<approverRoles.length; i++){
                if(approverRoles[i] == Types.Role.Admin 
                        || approverRoles[i] == Types.Role.Shipper) {
                    return true;
                }
            }
            return false;
        }

        if(requestedRole == Types.Role.Driver) {
            for(uint i=0; i<approverRoles.length; i++){
                if(approverRoles[i] == Types.Role.Admin 
                        || approverRoles[i] == Types.Role.Shipper 
                        || approverRoles[i] == Types.Role.Driver) {
                    return true;
                }
            }
            return false;
        }

        if(requestedRole == Types.Role.Receiver) {
            for(uint i=0; i<approverRoles.length; i++){
                if(approverRoles[i] == Types.Role.None) {
                    return false;
                }
            }
            return true;
        }

        return false;
        
    }

    function isUserRegistered(address _userAddr) external view returns(bool) {
        if(bytes(users[_userAddr].userName).length > 0) {
            return true;
        }
        
        revert Errors.UserNotRegistered(_userAddr, "User does not exists");
    }

    function getUserGeoHash(address _addr) external view returns (string memory) {
        return users[_addr].geoHash;
    }

    function hasRoleShipperAndReceiver(address _shipper, address _receiver) external  view {
        Types.Role[] memory receiverRoles = users[_receiver].role;

        bool isShipper = false;
        bool isReceiver = false;

        for(uint i = 0; i<receiverRoles.length; i++) {
            if(receiverRoles[i] == Types.Role.Receiver || receiverRoles[i] == Types.Role.Admin) {
                isReceiver = true;
                break;
            }
        }

        if(!isReceiver) {
            revert Errors.NotAuthorized({userAddress : _receiver, errMsg :"Receiver address provided doesn't have receiver or admin role"});
        }

        Types.Role[] memory shipperRoles = users[_shipper].role;
        for(uint i = 0; i<shipperRoles.length; i++) {
            if(shipperRoles[i] == Types.Role.Shipper || shipperRoles[i] == Types.Role.Admin) {
                isShipper = true;
                break;
            }
        }

        if(!isShipper) {
            revert Errors.NotAuthorized({userAddress : _shipper, errMsg :"Shipper address provided doesn't have shipper or admin role"});
        }
    }

    function hasRoleShipper(address _addr) external view {
        Types.Role[] memory userRoles = users[_addr].role;

        bool isShipper = false;

        for(uint i=0; i<userRoles.length; i++) {
            if(userRoles[i] == Types.Role.Shipper || userRoles[i] == Types.Role.Admin) {
                isShipper = true;
                break;
            }
        }

        if(!isShipper) {
            revert Errors.NotAuthorized({userAddress : _addr, errMsg :"User address provided doesn't have shipper or admin role"});
        }
    }

    function hasRoleDriver(address _addr) external view {
        Types.Role[] memory userRoles = users[_addr].role;

        bool isDriver = false;

        for(uint i=0; i<userRoles.length; i++) {
            if(userRoles[i] == Types.Role.Driver || userRoles[i] == Types.Role.Admin) {
                isDriver = true;
                break;
            }
        }

        if(!isDriver) {
            revert Errors.NotAuthorized({userAddress : _addr, errMsg :"User address provided doesn't have Driver or admin role"});
        }
    }

    function hasRoleReceiver(address _addr) external view {
        Types.Role[] memory userRoles = users[_addr].role;

        bool isReceiver = false;

        for(uint i=0; i<userRoles.length; i++) {
            if(userRoles[i] == Types.Role.Receiver || userRoles[i] == Types.Role.Admin) {
                isReceiver = true;
                break;
            }
        }

        if(!isReceiver) {
            revert Errors.NotAuthorized({userAddress : _addr, errMsg :"User address provided doesn't have receiver or admin role"});
        }
    }

    function hasNoneRole(address _addr) external view {
        Types.Role[] memory userRoles = users[_addr].role;

        bool isNoneRole = false;

        for(uint i=0; i<userRoles.length; i++) {
            if(userRoles[i] == Types.Role.None) {
                isNoneRole = true;
                break;
            }
        }

        if(isNoneRole) {
            revert Errors.NotAuthorized({userAddress : _addr, errMsg :"User address provided have none role"});
        }
    }

    function deductStars(address _addr) external  {
        Types.User memory user = users[_addr];
        uint intStars = user.starsInInt;
        intStars -= 1;
        if(intStars >= 0) {
            users[_addr].starsInInt = intStars;
            uint rem = intStars % 10;
            uint quot = intStars / 10;
            users[_addr].starsInString = string(abi.encodePacked(Strings.toString(quot), ".", Strings.toString(rem)));
        }
    }

    
}