// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/8_delegatecall/Proxy/CounterV1.sol";

// Implementation V2
contract CounterV2 is CounterV1 {
    // 只能在原布局末尾追加,必须保持之前的slot的含义不变,不然数据就会错乱
    string public label; // slot 3

    function setLabel(string calldata newLabel) external onlyOwner {
        label = newLabel;
    }

    function decrement() external {
        number -= 1;
    }
}
