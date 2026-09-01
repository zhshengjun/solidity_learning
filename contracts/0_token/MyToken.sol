// SPDX-License-Identifier: MIT
pragma solidity ^0.8.36;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    address immutable owner;
    mapping(address => uint256) ethDeposits;
    mapping(address => uint256) tokenDeposits;

    constructor() ERC20("stupidzhang", "SZ") {
        _mint(address(this), 1_000 * 10 ** decimals());
        owner = msg.sender;
    }

    error NotOwner();
    error InsufficientEthDeposit();
    error EthTransferFailed();
    error InsufficientTokenDeposit();
    error InsufficientDistributableTokens();

    uint256 totalTokenDeposits; // 用户的存款

    // 拦截器
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // 存款ETH
    function depositEth() public payable {
        ethDeposits[msg.sender] += msg.value;
    }

    // 取款ETH
    function withdrawEth(uint256 amount) external {
        uint256 deposited = ethDeposits[msg.sender];
        if (deposited < amount) revert InsufficientEthDeposit();

        // 先扣账，再进行外部调用
        unchecked {
            ethDeposits[msg.sender] = deposited - amount;
        }

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert EthTransferFailed();
    }

    //合约的ETH
    function ethValue() external view returns (uint256) {
        return address(this).balance;
    }

    // 这里是分发币逻辑,铸造的在合约里面
    function distribute(address to, uint256 amount) external payable onlyOwner {
        // 用户存款不能被 owner 分发
        uint256 available = balanceOf(address(this)) - totalTokenDeposits;
        if (available < amount) revert InsufficientDistributableTokens();

        _transfer(address(this), to, amount);
    }

    // 存款 token
    function depositToken(uint256 amount) external {
        // _transfer 自带余额检查，无需提前 balanceOf
        _transfer(msg.sender, address(this), amount);

        tokenDeposits[msg.sender] += amount;
        totalTokenDeposits += amount;
    }

    // 取款token
    function withdrawToken(uint256 amount) public payable {
        uint256 deposited = tokenDeposits[msg.sender];
        if (deposited < amount) revert InsufficientTokenDeposit();
        // 先扣减再转账
        unchecked {
            tokenDeposits[msg.sender] = deposited - amount;
        }
        totalTokenDeposits -= amount;

        _transfer(address(this), msg.sender, amount);
    }
}
