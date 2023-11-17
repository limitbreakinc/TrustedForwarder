// SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.8.9;

import {BaseTest} from "../TestBase.t.sol";
import {GarlicPress} from "src/GarlicPress.sol"; 
import {GarlicBulb} from "src/GarlicBulb.sol";
import {MockReceiverContract} from "../mocks/MockReceiverContract.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console.sol";

contract BenchmarkGarlicBulbWithSigner is BaseTest {
    GarlicPress public garlicPress;
    address public garlicBulbImplementation;
    GarlicBulb public garlicBulb;
    MockReceiverContract public mockReceiver;

    function setUp() public override {
        super.setUp();

        garlicBulbImplementation = address(new GarlicBulb());
        GarlicBulb(garlicBulbImplementation).__GarlicBulb_init(address(this), address(this));

        garlicPress = new GarlicPress(garlicBulbImplementation);
        address clone = garlicPress.cloneGarlicBulb(address(this), signer, bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this))))));
        garlicBulb = GarlicBulb(clone);
        mockReceiver = new MockReceiverContract(address(garlicPress));
    }

    function testForwardCallWithSigner_base(address sender) public {
        vm.assume(sender != address(this) && sender != address(0));

        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithRevert.selector, sender);
        bytes32 digest = ECDSA.toTypedDataHash(
            garlicBulb.domainSeparatorV4(),
            keccak256(
                abi.encode(
                    garlicBulb.APP_SIGNER_TYPEHASH(),
                    keccak256(message),
                    address(mockReceiver),
                    sender
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);

        address clone2 = garlicPress.cloneGarlicBulb(address(this), signer, bytes32(uint256(keccak256(abi.encodePacked(address(2), address(this))))));
        GarlicBulb garlicBulb2 = GarlicBulb(clone2);

        console.logBytes32(garlicBulb.domainSeparatorV4());
        console.logBytes32(garlicBulb2.domainSeparatorV4());
        console.logBytes32(GarlicBulb(garlicBulbImplementation).domainSeparatorV4());

        vm.prank(sender);
        garlicBulb.forwardCall(address(mockReceiver), message, GarlicBulb.SignatureECDSA(v, r, s));
    }
}