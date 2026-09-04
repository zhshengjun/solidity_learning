// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

//题目描述：反转一个字符串。输入 "abcde"，输出 "edcba"
contract ReverseString {
    constructor() {}

    function reverse(string memory text) external pure returns (string memory) {
        // 先转为bytes数组
        bytes memory arr = bytes(text);
        uint length = arr.length;
        // 原地调换
        for (uint index = 0; index <= length / 2; index++) {
            bytes1 temp = arr[index];
            arr[index] = arr[length - 1 - index];
            arr[length - 1 - index] = temp;
        }

        return string(arr);
    }
}
