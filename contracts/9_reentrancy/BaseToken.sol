// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract BaseContract is ReentrancyGuard {
    mapping(address => uint256) balances;

    event DespoitBalance(address indexed address_, uint256 amount);
    event WithdrawBalance(address indexed address_, uint256 amount);

    error InsufficientBalance();

    error Withdraw();

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit DespoitBalance(msg.sender, msg.value);
    }

    // 不安全的转账,容易造成重入
    function vulnerableWithdraw() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, InsufficientBalance());

        // 转账
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, Withdraw());
        // 扣除余额
        balances[msg.sender] = 0;
        emit WithdrawBalance(msg.sender, balance);
    }

    // 安全的转账-CEI
    function safeWithdraw() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, InsufficientBalance());

        // 扣除余额
        balances[msg.sender] = 0;
        // 转账
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, Withdraw());

        emit WithdrawBalance(msg.sender, balance);
    }

    // 安全的转账-Libary
    function safe2LibaryWithdraw() external nonReentrant {
        uint256 balance = balances[msg.sender];
        require(balance > 0, InsufficientBalance());

        // 转账
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, Withdraw());
        // 扣除余额
        balances[msg.sender] = 0;
        emit WithdrawBalance(msg.sender, balance);
    }

    function getBalace() external view returns (uint256) {
        return balances[msg.sender];
    }
}
