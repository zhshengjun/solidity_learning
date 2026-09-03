// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract TargetContract {
    uint256 public value;
    address public sender;

    event ValueChanged(address indexed caller, uint256 newValue);

    function updateValue(uint256 _value) external {
     value = _value;
        sender = msg.sender;
        emit ValueChanged(msg.sender, _value);
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}

contract CallMethod {
    mapping(address => uint256) balances;

    error CallError();

    event CallResult(address indexed target, bool success, bytes data);

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "insufficient balance");
        // 扣减余额
        balances[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");

        if (!success) {
            revert CallError();
        }
    }

    function call(address target, uint256 value_) external {
        (bool success, bytes memory data) = target.call(
            abi.encodeWithSignature("updateValue(uint256)", value_)
        );
        require(success, "call error");
        emit CallResult(target, success, data);
    }

    function delegatecall(address target, uint256 value_) external {
        (bool success, bytes memory data) = target.delegatecall(
            abi.encodeWithSignature("updateValue(uint256)", value_)
        );
        require(success, "call error");
        emit CallResult(target, success, data);
    }

    function staticcall(address target_) external returns (uint256) {
        (bool success, bytes memory data) = target_.staticcall(
            abi.encodeWithSignature("getValue()")
        );
        require(success, "call error");
        emit CallResult(target_, success, data);
        // 这是转吗, abi 的必须这样
        return abi.decode(data, (uint256));
    }
}
