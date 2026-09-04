// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 用户建模实体
 */
struct User {
    string name;
    string email;
    uint256 balance;
    uint256 registerAt;
    bool exists;
}

/**
 * 注册用户
 */
contract UserManageConstract {
    // 用户全量地址
    address[] public userAddress;
    // 地址到用户信息的映射
    mapping(address => User) public users;

    uint constant max_value = 1000;

    function register(
        string calldata name,
        string calldata email
    ) public returns (bool) {
        address sender = msg.sender;
        require(users[sender].exists == false, "address has register"); // 检查是否存在

        require(userAddress.length < max_value, "register number max");

        users[sender] = User({
            name: name,
            email: email,
            balance: 0,
            registerAt: block.timestamp,
            exists: true
        });
        userAddress.push(sender);
        return true;
    }

    function updateProfile(
        string calldata name,
        string calldata email
    ) public returns (bool) {
        address sender = msg.sender;
        require(users[sender].exists == true, "address not register");
        users[sender].name = name;
        users[sender].email = email;
        return true;
    }

    function deposit(uint256 amount) public returns (bool) {
        address sender = msg.sender;
        require(users[sender].exists == true, "account not registered");
        users[sender].balance = amount;
        return true;
    }

    function withdraw(uint256 amount) public returns (bool) {
        address sender = msg.sender;
        require(users[sender].exists == true, "account not registered");
        uint256 balance = users[sender].balance;

        require(balance >= amount, "insufficient account balance");

        users[sender].balance = balance - amount;
        return true;
    }

    function queryUserInfo(
        address addr
    )
    public
    view
    returns (
        string memory name,
        string memory email,
        uint256 balance,
        uint256 registerAt
    )
    {
        User storage user = users[addr];
        require(user.exists, "address not register");

        return (user.name, user.email, user.balance, user.registerAt);
    }

    function queryAll() public view returns (User[] memory) {
        uint total = userAddress.length;
        // User[total] results; 这样的写法是错误地,total 只有运行时才知道具体多少
        User[] memory results = new User[](total);

        for (uint i = 0; i < total; i++) {
            results[i] = users[userAddress[i]];
        }
        return results;
    }

    function ranageUser(
        uint start,
        uint end
    ) public view returns (User[] memory) {
        // 采用 0-based、左闭右开：[start, end)
        require(
            start >= 1 && start <= end && end <= userAddress.length,
            "invalid range"
        );

        uint256 count = end - start + 1;
        User[] memory results = new User[](count);

        for (uint256 i = 0; i < count; i++) {
            results[i] = users[userAddress[start - 1 + i]];
        }
        return results;
    }
}
