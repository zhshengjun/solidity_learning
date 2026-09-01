// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract AnonymousEvent {
    uint256 internal immutable counter;

    event QueryEvent(
        address indexed from,
        address indexed a,
        address indexed b,
        address indexed c,
        uint256 value
    ) anonymous;

    // 匿名最多4个
    // event QueryEvent2(
    //     address indexed from,
    //     address indexed a,
    //     address indexed b,
    //     address indexed c,
    //     address indexed d ,
    //     uint256 value
    // ) anonymous;

    constructor() {
        counter = 1024;
    }

    function queryCounter() public {
        emit QueryEvent(
            msg.sender,
            address(0x1),
            address(0x2),
            address(0x3),
            counter
        );
    }
}
