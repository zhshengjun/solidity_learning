// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "contracts/6_librarys/InternalLib.sol";

contract InternalUse {
    using InternalLib for uint256;

    function add(uint256 x, uint256 y) external pure returns (uint256) {
        return x.add(y);
    }

    function sub(uint256 x, uint256 y) external pure returns (uint256) {
        return InternalLib.sub(x, y);
    }
}
