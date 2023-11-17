// SPDX-License-Identifier: MIT
pragma solidity <=0.8.9;

import "forge-std/console.sol";
import "src/GarlicERC2771Context.sol";

contract MockReceiverContract is GarlicERC2771Context {
    constructor(address garlicPress) GarlicERC2771Context(garlicPress) {}

    function findTheSenderWithRevert(address expectedSender) external payable {
        if (_msgSender() != expectedSender) {
            revert("MockReceiverContract__SenderDoesNotMatch");
        }
    }

    function findTheSenderWithReturnValue(address expectedSender) external view returns (bool) {
        return _msgSender() == expectedSender;
    }

    function getTheData(bytes calldata expectedData) external view returns (bool) {
        return keccak256(_msgData()) == keccak256(expectedData);
    }

    function getTheDataBytesReturn() external view returns (bytes memory) {
        return _msgData();
    }
}