// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";
import {TrustedForwarderFactory} from "src/TrustedForwarderFactory.sol"; 
import {TrustedForwarder} from "src/TrustedForwarder.sol";
import {MockReceiverContract} from "../mocks/MockReceiverContract.sol";

contract BenchmarkTrustedForwarder is Test {
    TrustedForwarderFactory public factory;
    address public forwarderImplementation;
    TrustedForwarder public forwarder;
    MockReceiverContract public mockReceiver;

    uint256 signerKey;
    address signerAddress;

    function setUp() public {
        forwarderImplementation = address(new TrustedForwarder());
        TrustedForwarder(forwarderImplementation).__TrustedForwarder_init(address(this), address(this));

        factory = new TrustedForwarderFactory(forwarderImplementation);
        address clone = factory.cloneTrustedForwarder(address(this), address(0), bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this))))));
        forwarder = TrustedForwarder(clone);

        mockReceiver = new MockReceiverContract(address(factory));
    }

    function testForwardCall_msgData(bytes calldata testData) public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.getTheData.selector, testData);

        bytes memory retVal = forwarder.forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(0, bytes32(0), bytes32(0)));
        bool decoded = abi.decode(retVal, (bool));
        assertEq(decoded, true);
    }
}