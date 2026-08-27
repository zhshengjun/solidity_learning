// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVault {
    error InvalidToken();
    error TransferFailed();
    error InsufficientDeposit();

    IERC20 public immutable token;
    mapping(address => uint256) public deposits;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address tokenAddress) {
        if (tokenAddress == address(0)) revert InvalidToken();
        token = IERC20(tokenAddress);
    }

    //仅支持标准 ERC20；手续费 Token 需按实际到账量记账。
    function deposit(uint256 amount) external {
        if (!token.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }

        deposits[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        uint256 deposited = deposits[msg.sender];
        if (deposited < amount) revert InsufficientDeposit();

        // 先扣账，再转账
        unchecked {
            deposits[msg.sender] = deposited - amount;
        }

        if (!token.transfer(msg.sender, amount)) {
            revert TransferFailed();
        }

        emit Withdrawn(msg.sender, amount);
    }


}
