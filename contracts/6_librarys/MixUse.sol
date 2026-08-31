// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "contracts/6_library/MixLib.sol";

contract MixlUse {
    using MixLib for uint256;

    function add(uint256 x, uint256 y) external pure returns (uint256) {
        return x.add(y);
    }

    function sub(uint256 x, uint256 y) external pure returns (uint256) {
        return x.sub(y);
    }
}
