// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.7.0
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Bridgeable} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Bridgeable.sol";

contract MyToken is ERC20, ERC20Bridgeable, ERC20Permit, AccessControl {
    address internal constant SUPERCHAIN_TOKEN_BRIDGE = 0x4200000000000000000000000000000000000028;

    error Unauthorized();

    constructor(address defaultAdmin)
    ERC20("MyToken", "MTK")
    ERC20Permit("MyToken")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    /**
     * @dev Checks if the caller is the predeployed SuperchainTokenBridge. Reverts otherwise.
     *
     * IMPORTANT: The predeployed SuperchainTokenBridge is only available on chains in the Superchain.
     */
    function _checkTokenBridge(address caller) internal pure override {
        if (caller != SUPERCHAIN_TOKEN_BRIDGE) revert Unauthorized();
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC20Bridgeable, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
