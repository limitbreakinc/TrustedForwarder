// SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.8.9;

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
        vm.assume(testData.length > 0);
        bytes memory message = abi.encodeWithSelector(mockReceiver.getTheData.selector, testData);

        bytes memory retVal = forwarder.forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(0, bytes32(0), bytes32(0)));
        bytes memory decoded = abi.decode(retVal, (bytes));
        if (decoded.length >= 4) {
            bytes memory truncated = new bytes(decoded.length - 4);
            for (uint256 i = 4; i < decoded.length; i++) {
                truncated[i - 4] = decoded[i];
            }

            bytes memory originalMessage = abi.decode(truncated, (bytes));
            assertEq(keccak256(originalMessage), keccak256(testData));
        }
    }
}