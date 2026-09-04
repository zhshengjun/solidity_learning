// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum State {
    Progress, // 进行中
    Miscarry, //流产
    Successed, // 达到目标
    Withdraw, // 提取金额
    End // 结束
}

contract MyCrowdfunding {
    // owner
    address private immutable owner;

    // 众筹金额
    uint256 public immutable targetAmount;
    // 最小参与金额
    uint256 public immutable minValue;

    // 截止时间戳
    uint256 public immutable deadline;
    // 活动最新状态
    State internal latestState;

    // 已众筹金额
    uint256 public raisedAmount;

    // 众筹的明细
    mapping(address => uint256) public contributors;

    constructor(uint256 amount, uint256 _minValue, uint256 timestamp) {
        owner = msg.sender;
        targetAmount = amount;
        minValue = _minValue;
        deadline = timestamp;
    }

    error NotOwner(); // 必须是持有者
    error NotProcess(); // 必须是进行中
    error NotEnd(); // 必须已结束
    error NotSuccessed(); // 取款成功
    error ClaimFailed(); // 取款失败
    error NotBalance(); // 余额不足
    error RepeatWithdraw(); // 重复取款
    error NotWithdraw(); // 未取款取款
    error NotValue(); // 未达到最小金额

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyProcess() {
        _checkLatestState();
        if (latestState != State.Progress) revert NotProcess();
        _;
    }

    modifier onlyEnd() {
        if (latestState != State.End) revert NotEnd();
        _;
    }

    modifier onlySuccessed() {
        if (latestState != State.Successed) revert NotSuccessed();
        _;
    }

    function deposit() public payable onlyProcess {
        _checkLatestState();

        if (latestState == State.End) revert NotProcess();

        if (msg.value < minValue) revert NotValue();

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function claim() public {
        if (latestState != State.Miscarry && latestState != State.End)
            revert NotEnd();

        uint256 amount = contributors[msg.sender];

        contributors[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert ClaimFailed();
    }

    function withdraw() public onlyOwner onlySuccessed {
        if (latestState == State.Withdraw) revert RepeatWithdraw();
        _checkLatestState();
        if (latestState != State.Successed) revert NotSuccessed();
        uint256 amount = raisedAmount;
        if (amount == 0) revert NotBalance();

        // 先改状态
        latestState = State.Withdraw;
        raisedAmount = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert ClaimFailed();
    }

    function endCrow() public onlyOwner {
        _checkLatestState();
        if (latestState != State.Withdraw && latestState != State.Miscarry)
            revert NotWithdraw();

        if (latestState == State.Withdraw) {
            if (address(this).balance < raisedAmount) revert NotBalance();
        } else if (latestState != State.Miscarry) {
            revert NotWithdraw();
        }

        latestState = State.End;
    }

    function _checkLatestState() private {
        if (latestState != State.Progress || block.timestamp < deadline) return;

        latestState = raisedAmount >= targetAmount
            ? State.Successed
            : State.Miscarry;
    }
}
