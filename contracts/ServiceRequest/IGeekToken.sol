// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";

interface IGeekToken {
    function transferTokens(address to, uint256 cargoInsurableValue, Types.Acceptance acceptance) external;
}