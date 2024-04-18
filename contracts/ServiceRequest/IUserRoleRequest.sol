// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IUserRoleRequest {
    function hasRoleShipperOrAdminAndReceiver(address _shipper, address _receiver) external  view;
    function hasRoleShipperOrAdmin(address _addr) external view;
    function hasRoleDriver(address _addr) external view;
    function hasRoleReceiver(address _addr) external view;
    
    function getUserGeoHash(address _addr) external view returns (string memory);
    function isUserRegistered(address _userAddr) external view;
    function isAdmin(address _addr) view external returns (bool);
}