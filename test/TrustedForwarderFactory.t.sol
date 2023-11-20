// SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.8.9;

import "forge-std/console.sol";
import {BaseTest} from "./TestBase.t.sol";
import {TrustedForwarderFactory} from "../src/TrustedForwarderFactory.sol"; 
import {TrustedForwarder} from "../src/TrustedForwarder.sol";
import {MockReceiverContract} from "./mocks/MockReceiverContract.sol";

contract TrustedForwarderFactoryTest is BaseTest {
    TrustedForwarderFactory public factory;
    address public trustedForwarderImplementation;

    function setUp() public override {
        trustedForwarderImplementation = address(new TrustedForwarder());
        TrustedForwarder(trustedForwarderImplementation).__TrustedForwarder_init(address(this), address(this));

        factory = new TrustedForwarderFactory(trustedForwarderImplementation);
    }

    function testDeployment() public {
        assertEq(address(factory.trustedForwarderImplementation()), trustedForwarderImplementation);
    }

    function testClone_appSignerAssigned(address signer, address badAddress) public {
        vm.assume(badAddress != signer);
        assumeAddressNotBadAddress(signer);
        assumeAddressNotBadAddress(badAddress);
        bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this)))));
        address forwarder = factory.cloneTrustedForwarder(address(this), address(this), salt);
        assertEq(TrustedForwarder(forwarder).signer(), address(this));
        assertEq(TrustedForwarder(forwarder).owner(), address(this));
        
        assertEq(TrustedForwarder(forwarder).signer(), address(this));
        assert(TrustedForwarder(forwarder).signer() != badAddress);
    }

    function testCloneAndReinitialize(address badAddress) public {
        vm.assume(badAddress != address(this));
        bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this)))));
        address forwarder = factory.cloneTrustedForwarder(address(this), address(this), salt);

        address signerAddress = TrustedForwarder(forwarder).signer();
        
        assertEq(signerAddress, address(this));

        vm.expectRevert("Initializable: contract is already initialized");
        TrustedForwarder(forwarder).__TrustedForwarder_init(badAddress, badAddress);

        signerAddress = TrustedForwarder(forwarder).signer();

        assertEq(signerAddress, address(this));
    }

    function testForwardCall_base_revert_withSig(address sender) public {
        vm.assume(sender != address(this) && sender != address(0));
        bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this)))));
        address forwarder = factory.cloneTrustedForwarder(address(this), address(0), salt);

        MockReceiverContract mockReceiver = new MockReceiverContract(address(factory));

        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithRevert.selector, sender);

        vm.startPrank(sender);
        TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(0, bytes32(0), bytes32(0)));
    }

    function testForwardCall_base_revert_noSig(address sender) public {
        vm.assume(sender != address(this) && sender != address(0));
        bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this)))));
        address forwarder = factory.cloneTrustedForwarder(address(this), address(0), salt);

        MockReceiverContract mockReceiver = new MockReceiverContract(address(factory));

        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithRevert.selector, sender);
        vm.deal(sender, 1 ether);

        vm.startPrank(sender);
        TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message);
    }

    function testForwardCall_base_return(address sender) public {
        vm.assume(sender != address(this) && sender != address(0));
        bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this)))));
        address forwarder = factory.cloneTrustedForwarder(address(this), address(0), salt);

        MockReceiverContract mockReceiver = new MockReceiverContract(address(factory));

        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithReturnValue.selector, sender);

        vm.startPrank(sender);
        bytes memory retVal = TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(0, bytes32(0), bytes32(0)));

        assertEq(abi.decode(retVal, (bool)), true);

        vm.stopPrank();

        retVal = TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(0, bytes32(0), bytes32(0)));

        assertEq(abi.decode(retVal, (bool)), false);
    }

    function testForwardCall_nonMatchingSender_revert(address sender) public {
        vm.assume(sender != address(this) && sender != address(0));
        bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this)))));
        address forwarder = factory.cloneTrustedForwarder(address(this), address(0), salt);

        MockReceiverContract mockReceiver = new MockReceiverContract(address(factory));

        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithRevert.selector, address(this));

        vm.startPrank(sender);
        vm.expectRevert("MockReceiverContract__SenderDoesNotMatch");
        TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(0, bytes32(0), bytes32(0)));
    }

    function testForwardCall_getData_largeDataReturn() public {
        bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this)))));
        address forwarder = factory.cloneTrustedForwarder(address(this), address(0), salt);

        MockReceiverContract mockReceiver = new MockReceiverContract(address(factory));

        bytes memory message = abi.encodeWithSelector(mockReceiver.getSomeLargeData.selector);

        bytes memory retVal = TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(0, bytes32(0), bytes32(0)));
        string memory decodedVal = abi.decode(retVal, (string));
        console.log(decodedVal);
    }
}