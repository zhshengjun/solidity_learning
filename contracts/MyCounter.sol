// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyCounter {
    /**
     * 全局数字，用于计数
     */
    uint256 internal counter;

    constructor() {}

    event Increased(address indexed caller, uint256 value);

    /**
     * 这是我的测试计数器
     * 自增后，返回自增后的数字
     */
    function increase() public {
        uint256 value = ++counter;
        emit Increased(msg.sender, value);
    }

    /**
     * 返回最新的 counter
     */
    function getCounter() public view returns (uint256) {
        return counter;
    }
}
