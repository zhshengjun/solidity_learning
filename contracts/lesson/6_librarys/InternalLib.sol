// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library InternalLib {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        return x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        return x - y;
    }
}
