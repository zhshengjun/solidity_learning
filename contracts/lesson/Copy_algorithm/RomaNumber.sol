// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

contract RomaNumber {
    //a = {'I':1, 'V':5, 'X':10, 'L':50, 'C':100, 'D':500, 'M':1000}
    mapping(bytes1 => int256) private romas;

    constructor() {
        _initRoma();
    }

    function roma2Int(string calldata text) external view returns (uint256) {
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

    function int2Roma(uint256 number) external pure returns (string memory) {
        require(number > 0 && number < 4000, "range: 1-3999");

        uint16[13] memory values = [
            uint16(1000),
            900,
            500,
            400,
            100,
            90,
            50,
            40,
            10,
            9,
            5,
            4,
            1
        ];
        string[13] memory symbols = [
            "M",
            "CM",
            "D",
            "CD",
            "C",
            "XC",
            "L",
            "XL",
            "X",
            "IX",
            "V",
            "IV",
            "I"
        ];

        string memory result;

        for (uint256 index; index < values.length; index++) {
            while (number >= values[index]) {
                result = string.concat(result, symbols[index]);
                number -= values[index];
            }
        }

        return result;
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
