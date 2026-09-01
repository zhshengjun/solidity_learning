// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/8_delegatecall/CounterV1.sol";
import "contracts/8_delegatecall/CounterV2.sol";

// Proxy
contract SimpleProxy {
    // 专用哈希槽，不占用普通的 slot 0、1、2……
    // bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 private constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    //bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
    bytes32 private constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor(address implementation_, uint256 initialNumber) {
        _setAdmin(msg.sender);
        _setImplementation(implementation_);

        // 在 Proxy 的 storage 中执行初始化
        (bool success, bytes memory reason) = implementation_.delegatecall(
            abi.encodeWithSignature("initialize(uint256)", initialNumber)
        );

        if (!success) {
            assembly {
                revert(add(reason, 32), mload(reason))
            }
        }
    }

    function implementation() external view returns (address) {
        return _implementation();
    }

    function upgradeTo(address newImplementation) external {
        require(msg.sender == _admin(), "not admin");
        _setImplementation(newImplementation);
    }

    function _setImplementation(address newImplementation) private {
        require(newImplementation.code.length > 0, "not contract");

        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    function _implementation() private view returns (address value) {
        assembly {
            value := sload(_IMPLEMENTATION_SLOT)
        }
    }

    function _setAdmin(address newAdmin) private {
        assembly {
            sstore(_ADMIN_SLOT, newAdmin)
        }
    }

    function _admin() private view returns (address value) {
        assembly {
            value := sload(_ADMIN_SLOT)
        }
    }

    function _delegate(address target) private {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _delegate(_implementation());
    }

    receive() external payable {
        _delegate(_implementation());
    }
}
