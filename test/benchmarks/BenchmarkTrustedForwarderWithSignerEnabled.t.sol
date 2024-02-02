// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {BaseTest} from "../TestBase.t.sol";
import {TrustedForwarderFactory} from "src/TrustedForwarderFactory.sol"; 
import {TrustedForwarder} from "src/TrustedForwarder.sol";
import {MockReceiverContract} from "../mocks/MockReceiverContract.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console.sol";

contract BenchmarkTrustedForwarderWithSigner is BaseTest {

    function setUp() public override {
        super.setUp();

        forwarderImplementation = address(new TrustedForwarder());
        TrustedForwarder(forwarderImplementation).__TrustedForwarder_init(address(this), address(this));

        factory = new TrustedForwarderFactory(forwarderImplementation);
        address clone = factory.cloneTrustedForwarder(address(this), signer, bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this))))));
        forwarder = TrustedForwarder(clone);
        mockReceiver = new MockReceiverContract(address(factory));
    }

    function testForwardCallWithSigner_signerEnabled(address sender) public {
        vm.assume(sender != address(this) && sender != address(0));

        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithRevert.selector, sender);
        bytes32 digest = ECDSA.toTypedDataHash(
            forwarder.domainSeparatorV4(),
            keccak256(
                abi.encode(
                    forwarder.APP_SIGNER_TYPEHASH(),
                    keccak256(message),
                    address(mockReceiver),
                    sender
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);

        vm.prank(sender);
        forwarder.forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
    }
}