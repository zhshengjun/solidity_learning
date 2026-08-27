// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SumContract {
    // 构造函数
    constructor() {}

    // 这是 memory
    function getSumMemory(uint[] memory nums) public pure returns (uint) {
        uint sum = 0;
        uint length = nums.length;
        for (uint i = 0; i < length; i++) {
            sum += nums[i];
        }

        return sum;
    }

    // 这是 calldata
    function getSumCallData(uint[] calldata nums) public pure returns (uint) {
        uint sum = 0;
        uint length = nums.length;
        for (uint i = 0; i < length; i++) {
            sum += nums[i];
        }
        return sum;
    }
}
