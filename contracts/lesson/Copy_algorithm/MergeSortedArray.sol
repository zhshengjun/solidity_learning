// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

contract MergeSortedArray {
    function merge(
        uint256[] calldata arr1,
        uint256[] calldata arr2
    ) external pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](arr1.length + arr2.length);
        uint256 left;
        uint256 right;
        uint256 index;

        while (left < arr1.length && right < arr2.length) {
            if (arr1[left] <= arr2[right]) {
                result[index++] = arr1[left++];
            } else {
                result[index++] = arr2[right++];
            }
        }

        while (left < arr1.length) {
            result[index++] = arr1[left++];
        }

        while (right < arr2.length) {
            result[index++] = arr2[right++];
        }

        return result;
    }
}
