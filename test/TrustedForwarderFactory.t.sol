// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/console.sol";
import {BaseTest} from "./TestBase.t.sol";
import {TrustedForwarderFactory} from "../src/TrustedForwarderFactory.sol"; 
import {TrustedForwarder} from "../src/TrustedForwarder.sol";
import {MockReceiverContract} from "./mocks/MockReceiverContract.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TrustedForwarderFactoryTest is BaseTest {

    function setUp() public override {
        forwarderImplementation = address(new TrustedForwarder());
        TrustedForwarder(forwarderImplementation).__TrustedForwarder_init(address(this), address(this));

        factory = new TrustedForwarderFactory(forwarderImplementation);
    }

    function testDeployment() public {
        assertEq(address(factory.trustedForwarderImplementation()), forwarderImplementation);
    }

    function testClone_EventEmitted(bytes32 salt) public {
        bytes32 computedSalt = keccak256(abi.encode(address(this), salt));
        address implementation = factory.trustedForwarderImplementation();
        address cachedFactory = address(factory);

        address predicted;
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), cachedFactory)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), computedSalt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
        vm.expectEmit(true, true, true, true);
        emit TrustedForwarderCreated(address(this), predicted);
        factory.cloneTrustedForwarder(address(this), address(this), salt);
    }

    function testClone_RevertOnSameSaltAndSender(address sender, bytes32 salt) public {
        assumeAddressNotBadAddress(sender);

        factory.cloneTrustedForwarder(address(this), address(this), salt);

        vm.expectRevert("ERC1167: create2 failed");
        factory.cloneTrustedForwarder(address(this), address(this), salt);
    }

    function testClone_AllowDifferentSenderSameSalt(address sender1, address sender2, bytes32 salt) public {
        vm.assume(sender1 != sender2);
        assumeAddressNotBadAddress(sender1);
        assumeAddressNotBadAddress(sender2);

        vm.prank(sender1);
        address clone1 = factory.cloneTrustedForwarder(address(this), sender1, salt);
        vm.prank(sender2);
        address clone2 = factory.cloneTrustedForwarder(address(this), sender2, salt);

        assert(clone1 != clone2);
    }

    function testClone_appSignerAssigned(address signer, address badAddress) public {
        vm.assume(badAddress != signer);
        vm.assume(badAddress != address(this));
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

    function testClone_BadInitData() public {
        vm.expectRevert(abi.encodeWithSelector(TrustedForwarderFactory.TrustedForwarderFactory__TrustedForwarderInitFailed.selector, address(0), address(0)));
        factory.cloneTrustedForwarder(address(0), address(0), bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this))))));
    }

    function testClone_isTrustedForwarder(bytes32 salt) public {
        bytes32 computedSalt = keccak256(abi.encode(address(this), salt));
        address implementation = factory.trustedForwarderImplementation();
        address cachedFactory = address(factory);

        address predicted;
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), cachedFactory)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), computedSalt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
        assertEq(factory.isTrustedForwarder(predicted), false);
        address forwarder = factory.cloneTrustedForwarder(address(this), address(this), salt);
        assertEq(factory.isTrustedForwarder(forwarder), true);
        assertEq(predicted, forwarder);
    }
}