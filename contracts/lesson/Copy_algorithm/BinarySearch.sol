// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

contract BinarySearch {
    function binarySearch(
        uint256[] calldata array,
        uint256 target
    ) external pure returns (uint256) {
        uint256 left;
        uint256 right = array.length; // 右边界不包含
        while (left < right) {
            uint256 mid = left + (right - left) / 2;
            // mid =  (left + right) / 2;

            if (array[mid] == target) return mid + 1;

            if (array[mid] < target) {
                left = mid;
            } else {
                right = mid;
            }
        }

        return 0;
    }
}
