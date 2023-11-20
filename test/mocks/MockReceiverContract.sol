// SPDX-License-Identifier: MIT
pragma solidity <=0.8.9;

import "forge-std/console.sol";
import "src/TrustedForwarderERC2771Context.sol";

contract MockReceiverContract is TrustedForwarderERC2771Context {
    constructor(address factory) TrustedForwarderERC2771Context(factory) {}

    function findTheSenderWithRevert(address expectedSender) external payable {
        console.log("MockReceiverContract__findTheSenderWithRevert");
        console.logAddress(_msgSender());
        console.logAddress(expectedSender);
        if (_msgSender() != expectedSender) {
            revert("MockReceiverContract__SenderDoesNotMatch");
        }
    }

    function findTheSenderWithReturnValue(address expectedSender) external view returns (bool) {
        console.log("MockReceiverContract__findTheSenderWithReturnValue");
        console.logAddress(_msgSender());
        console.logAddress(expectedSender);
        return _msgSender() == expectedSender;
    }

    function getTheData(bytes calldata expectedData) external view returns (bool) {
        return keccak256(_msgData()) == keccak256(expectedData);
    }

    function getSomeLargeData() external pure returns (bytes memory) {
        bytes memory largeData = bytes("this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.");
        return largeData;
    }

    function getTheDataBytesReturn() external view returns (bytes memory) {
        return _msgData();
    }

    // fallback() external payable {
    //     console.log("MockReceiverContract__fallback");
    //     console.logBytes(msg.data);
    //     console.logBytes(_msgData());
    // }
}