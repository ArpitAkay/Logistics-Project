// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Errors {
    error AccessDenied(address from, string message);
    error NotSufficientFunds(address account, string message);

}