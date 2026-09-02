// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

contract ConterCreateContract {
    uint256 public counter;

    address public owner;

    constructor(address owner_) {
        owner = owner_;
        counter = 0;
    }
}

contract ContractFactory {
    function createContract() external returns (address) {
        ConterCreateContract counter = new ConterCreateContract(msg.sender);

        return address(counter);
    }

    function creater2Contract(
        string memory salt_
    ) external returns (address contractAddress) {
        bytes32 salt = keccak256(bytes(salt_));
        contractAddress = address(
            new ConterCreateContract{salt: salt}(msg.sender)
        );
        assert(contractAddress == predict(salt, msg.sender));
    }

    // 这是create2 提前计算地址的逻辑

    function predict(
        bytes32 salt,
        address deployer
    ) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(_initCode(deployer))
            )
        );

        return address(uint160(uint256(hash)));
    }

    function _initCode(address deployer) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                type(ConterCreateContract).creationCode,
                abi.encode(deployer)
            );
    }
}
