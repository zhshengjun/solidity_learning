// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Modifier {
    address immutable owner;

    uint256 private counter;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not contract owner");
        _;
    }

    function increase() public onlyOwner {
        counter += 1;
    }

    function deposit() public payable {}

    function withdraw(uint256 amount) external payable {
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");
    }
}
