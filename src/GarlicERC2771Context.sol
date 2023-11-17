// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (metatx/ERC2771Context.sol)
pragma solidity <=0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "./GarlicPress.sol";

/**
 * @title GarlicERC2771Context
 * @author Limit Break, Inc.
 * @notice Context variant that utilizes the GarlicPress contract to determine 
 */
abstract contract GarlicERC2771Context is Context {
    GarlicPress private immutable _garlicPress;

    constructor(address garlicPress) {
        _garlicPress = GarlicPress(garlicPress);
    }

    /**
     * @notice Returns true if the sender is a trusted forwarder, false otherwise.
     *
     * @dev    This function is required by ERC2771Context.
     * @dev    This function is virtual to allow for overriding in child contracts.
     *
     * @param forwarder The address to check.
     * @return True if the sender is a trusted forwarder, false otherwise.
     */
    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return _garlicPress.isTrustedForwarder(forwarder);
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (_garlicPress.isTrustedForwarder(msg.sender)) {
            if (msg.data.length >= 20) {
                // The assembly code is more direct than the Solidity version using `abi.decode`.
                /// @solidity memory-safe-assembly
                assembly {
                    sender := shr(96, calldataload(sub(calldatasize(), 20)))
                }
            } else {
                return super._msgSender();
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata data) {
        if (_garlicPress.isTrustedForwarder(msg.sender)) {
            assembly {
                // Get length of current calldata
                let len := calldatasize()
                // Create a slice that defaults to the entire calldata
                data.offset := 0
                data.length := len
                // If the calldata is > 20 bytes, it contains the sender address at the end
                // and needs to be truncated
                if gt(len, 0x14) {
                    data.length := sub(len, 0x14)
                }
            }
        } else {
            return super._msgData();
        }
    }
}
