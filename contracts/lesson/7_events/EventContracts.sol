// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventContract {
    uint256 internal immutable counter;

    event QueryEvent(
        address indexed from,
        address indexed a,
        address indexed b,
        uint256 value
    );

    // 非匿名,最多3个indexed
    // event QueryEvent2(
    //     address indexed from,
    //     address indexed a,
    //     address indexed b,
    //     address indexed c,
    //     uint256 value
    // );

    constructor() {
        counter = 256;
    }

    function queryCounter() public {
        emit QueryEvent(msg.sender, address(0x1), address(0x2), counter);
    }
}
