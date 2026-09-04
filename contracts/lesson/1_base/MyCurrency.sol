// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

/**
 *
 *
 **/
contract MyCurrency {
    enum State {
        Pending,
        Active,
        Closed
    }
    address immutable owner;

    State constant current = State.Pending;

    constructor() {
        owner = msg.sender;
    }

    /**
     *
     */
    function isActive(State state) public pure returns (bool) {
        return state == State.Active;
    }

    function convertUint(uint256 _value) public pure returns (uint8) {
        require(type(uint8).max >= _value, "value exceeds uint8 max ");
        return uint8(_value);
    }

    function overflow(uint256 _value) public pure returns (uint8) {
        require(type(uint8).max >= _value, "value needs lower than uint8 max");
        uint8 value2 = uint8(_value);
        return uint8(value2);
    }

    function transferAddress(address payable toAddress) public payable {
        // 转账原生的代币ETH
        (bool success,) = toAddress.call{value: msg.value}("");
        require(success, "ETH transfer failed");
    }
}
