// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BeggingContract is Ownable {
    // immutable 和  constant 都是不占用solt
    uint256 private immutable start_time;
    uint256 private immutable end_time;
    uint256 private constant TOP_K = 3;

    uint256 public totalDonate;

    // 记录
    mapping(address => uint256) public donates;
    address[] public tops;

    constructor(uint256 start_time_, uint256 end_time_) Ownable(msg.sender) {
        if (start_time_ >= end_time_) revert NotAllowTime();
        start_time = start_time_;
        end_time = end_time_;
    }

    event Donation(address indexed addr, uint256 amount);
    event Withdrawal(address indexed addr, uint256 amount);

    error InsufficientBalance();
    error WithdrawFailed();
    error OverBalance();
    error NotAllowTime();

    modifier allowTime() {
        uint256 nowTime = block.timestamp;
        require(nowTime >= start_time && nowTime <= end_time, NotAllowTime());
        _;
    }

    modifier onlyEnd() {
        uint256 nowTime = block.timestamp;
        require(nowTime > end_time, NotAllowTime());
        _;
    }

    function donate() external payable allowTime {
        require(msg.value > 0, InsufficientBalance());

        donates[msg.sender] += msg.value;
        totalDonate += msg.value;
        emit Donation(msg.sender, msg.value);
        _updateTop();
    }

    function withdraw(uint256 amount) external onlyOwner onlyEnd {
        require(totalDonate > 0 && amount > 0, InsufficientBalance());
        require(amount <= totalDonate, OverBalance());
        totalDonate -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, WithdrawFailed());
        emit Withdrawal(msg.sender, amount);
    }

    function _updateTop() private {
        bool exists = _topExist(msg.sender);
        if (!exists) {
            if (tops.length < TOP_K) {
                tops.push(msg.sender);
            } else if (donates[msg.sender] > donates[tops[TOP_K - 1]]) {
                tops[TOP_K - 1] = msg.sender;
            } else {
                return;
            }
        }
        // 触发排序
        _popSort();
    }

    /**
     * 冒泡排序
     */
    function _popSort() private {
        for (uint256 index = tops.length - 1; index > 0; index--) {
            if (donates[tops[index]] > donates[tops[index - 1]]) {
                address temp = tops[index - 1];
                tops[index - 1] = tops[index];
                tops[index] = temp;
            }
        }
    }

    function _topExist(address addr) private view returns (bool) {
        for (uint256 index = 0; index < tops.length; index++) {
            if (tops[index] == addr) {
                return true;
            }
        }
        return false;
    }
}
