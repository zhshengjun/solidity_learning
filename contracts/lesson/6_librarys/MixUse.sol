// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MixLib} from "./MixLib.sol";

contract MixlUse {
    using MixLib for uint256;
    error AdditionOverflow(uint256 x, uint256 y);

    function add(uint256 x, uint256 y) external pure returns (uint256 z) {
        try MixLib.add(x, y) {
            return z;
        } catch {
            revert AdditionOverflow(x, y);
        }
    }

    function sub(uint256 x, uint256 y) external pure returns (uint256) {
        return x.sub(y);
    }
}
