// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyArray {
    // 定长数组
    uint[5] public fixedArry = [1, 2, 3, 4, 5];

    // 动态数组
    uint[] public dynamicArry = [1, 2, 3, 4, 5];

    /**
     *定长的报错
     */
    function addFixed(uint value) public {
        // fixedArry.push(value);
    }

    function adddDynamic(uint value) public {
        dynamicArry.push(value);
    }

    function delFixed(uint8 index) public {
        delete fixedArry[index];
    }

    function delDynamic(uint8 index) public {
        dynamicArry[index] = dynamicArry[dynamicArry.length - 1];
        dynamicArry.pop();
    }

    /**
     * 这样保持原样,但是会消耗gas
     */
    function delDynamic2(uint8 index) public {
        uint length = dynamicArry.length;
        for (uint i = index; i < length - 1; i++) {
            dynamicArry[i] = dynamicArry[i + 1];
        }
        dynamicArry.pop();
    }

    /**
     * 获取动态元素
     */
    function getDynamic() public view returns (uint[] memory) {
        return dynamicArry;
    }
}
