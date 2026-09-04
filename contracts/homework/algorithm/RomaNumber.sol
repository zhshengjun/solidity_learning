// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

contract RomaNumber {
    //a = {'I':1, 'V':5, 'X':10, 'L':50, 'C':100, 'D':500, 'M':1000}
    mapping(bytes1 => int256) private romas;

    constructor() {
        _initRoma();
    }

    function conver(string calldata text) external view returns (uint256) {
        bytes memory arr = bytes(text);
        int256 result = 0;
        for (uint256 index; index < arr.length; index++) {
            int256 num = romas[arr[index]];

            if (index + 1 < arr.length && num < romas[arr[index + 1]]) {
                result -= num;
            } else {
                result += num;
            }
        }

        return uint256(result);
    }

    function _initRoma() private {
        romas["I"] = 1;
        romas["V"] = 5;
        romas["X"] = 10;
        romas["L"] = 50;
        romas["C"] = 100;
        romas["D"] = 500;
        romas["M"] = 1000;
    }
}
