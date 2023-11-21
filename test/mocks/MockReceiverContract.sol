// SPDX-License-Identifier: MIT
pragma solidity <=0.8.9;

import "forge-std/console.sol";
import "src/TrustedForwarderERC2771Context.sol";

contract MockReceiverContract is TrustedForwarderERC2771Context {

    struct ExampleReturn {
        uint256 uintValue;
        string stringValue;
        bool boolValue;
        uint8 uint8Value;
    }

    uint256 public uint256Value;
    string public stringValue;
    bool public boolValue;
    uint8 public uint8Value;

    constructor(address factory) TrustedForwarderERC2771Context(factory) {}

    function findTheSenderWithRevert(address expectedSender) external view {
        console.log("MockReceiverContract__findTheSenderWithRevert");
        console.logAddress(_msgSender());
        console.logAddress(expectedSender);
        if (_msgSender() != expectedSender) {
            revert("MockReceiverContract__SenderDoesNotMatch");
        }
    }

    function findTheSenderWithRevert_Payable(address expectedSender) external payable {
        console.log("MockReceiverContract__findTheSenderWithRevert");
        console.logAddress(_msgSender());
        console.logAddress(expectedSender);
        if (_msgSender() != expectedSender) {
            revert("MockReceiverContract__SenderDoesNotMatch");
        }
    }

    function panicFromOverflow() public pure returns (uint256) {
        uint256 a = 1;
        uint256 b = type(uint256).max;
        uint256 c = a + b;
        return c;
    }

    function panicFromOverflow_Payable() public payable returns (uint256) {
        uint256 a = 1;
        uint256 b = type(uint256).max;
        uint256 c = a + b;
        return c;
    }

    function revertFromAssert() public pure {
        assert(false);
    }

    function revertFromAssert_Payable() public payable {
        assert(false);
    }

    function findTheSenderWithReturnValue(address expectedSender) external view returns (bool) {
        return _msgSender() == expectedSender;
    }

    function findTheSenderWithReturnValue_Payable(address expectedSender) external payable returns (bool) {
        console.log("MockReceiverContract__findTheSenderWithReturnValue_Payable");
        console.logAddress(_msgSender());
        console.logAddress(expectedSender);
        return _msgSender() == expectedSender;
    }

    function getTheData(bytes calldata expectedData) external view returns (bool) {
        return keccak256(_msgData()) == keccak256(abi.encodeWithSelector(bytes4(keccak256("getTheData(bytes)")), expectedData));
    }

    function getTheData_Payable(bytes calldata expectedData) external payable returns (bool) {
        return keccak256(_msgData()) == keccak256(abi.encodeWithSelector(bytes4(keccak256("getTheData_Payable(bytes)")), expectedData));
    }

     function getSomeLargeData() external pure returns (bytes memory) {
        bytes memory largeData = bytes("this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.");
        return largeData;
    }   

    function getSomeLargeData_Payable() external payable returns (bytes memory) {
        bytes memory largeData = bytes("this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.");
        return largeData;
    }

    function getTheDataBytesReturn() external view returns (bytes memory) {
        return _msgData();
    }

    function getTheDataBytesReturn_Payable() external payable returns (bytes memory) {
        return _msgData();
    }

    function getMultipleValuesReturned() external pure returns (uint256, string memory, bool, uint8, ExampleReturn memory) {
        return (999, "hello world", true, uint8(5), ExampleReturn({uintValue: 222, stringValue: "hello world, but in the struct", boolValue: false, uint8Value: uint8(1)}));
    }

    function getMultipleValuesReturned_Payable() external payable returns (uint256, string memory, bool, uint8, ExampleReturn memory) {
       return (999, "hello world", true, uint8(5), ExampleReturn({uintValue: 222, stringValue: "hello world, but in the struct", boolValue: false, uint8Value: uint8(1)}));
    }

    function noReturnData() external pure {
        return;
    }

    function noReturnData_Payable() external payable {
        return;
    }

    function storeTheData(uint256 data1, string calldata data2, uint8 data3, bool data4) external {
        uint256Value = data1;
        stringValue = data2;
        uint8Value = data3;
        boolValue = data4;
    }

    function storeTheData_Payable(uint256 data1, string calldata data2, uint8 data3, bool data4) external payable {
        uint256Value = data1;
        stringValue = data2;
        uint8Value = data3;
        boolValue = data4;
    }

    // fallback() external payable {
    //     console.log("MockReceiverContract__fallback");
    //     console.logBytes(msg.data);
    //     console.logBytes(_msgData());
    // }
}