// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "contracts/6_library/ExternalLib.sol";

contract ExternalUse {
    using ExternalLib for uint256;
    function add(uint256 x, uint256 y) public pure returns (uint256) {
        return x.add(y);
    }

    function sub(uint256 x, uint256 y) public pure returns (uint256) {
        return ExternalLib.sub(x, y);
    }
}
