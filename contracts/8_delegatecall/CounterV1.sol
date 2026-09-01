// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Implementation V1
contract CounterV1 {
    uint256 public number; // slot 0
    address public owner; // slot 1
    uint256 private initialized; // slot 2

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        // 锁住 Implementation 自己
        // 不影响 Proxy 的 storage
        initialized = type(uint256).max;
    }

    function initialize(uint256 initialNumber) external {
        require(initialized == 0, "initialized");

        initialized = 1;
        owner = msg.sender;
        number = initialNumber;
    }

    function setNumber(uint256 newNumber) external onlyOwner {
        number = newNumber;
    }

    function increment() external {
        number += 1;
    }
}

