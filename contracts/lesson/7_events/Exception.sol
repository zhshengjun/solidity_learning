// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

contract Exception {
    mapping(address => uint256) balances;


    error InsufficientBalance();

    function deposit(uint256 amount) public {
        require(amount > 0, "amount must not zero");
        balances[msg.sender] += amount;
    }

    function withdraReqiredStr(uint256 amount) public { // 24089

        require(amount <= balances[msg.sender], "insufficient balance");
        balances[msg.sender] -= amount;
    }

    function withdraReqired(uint256 amount) public { // 23950

        require(amount <= balances[msg.sender], InsufficientBalance());
        balances[msg.sender] -= amount;
    }


    function withdrawAssert(uint256 amount) public { // 23854
        assert(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
    }

    function withdrawRevert(uint256 amount) public {// 24236

        if (amount <= balances[msg.sender]) revert InsufficientBalance();
        balances[msg.sender] -= amount;
    }

    function withdrawRevertStr(uint256 amount) public {// 24280 

        if (amount <= balances[msg.sender]) revert("insufficient balance");
        balances[msg.sender] -= amount;
    }
}
