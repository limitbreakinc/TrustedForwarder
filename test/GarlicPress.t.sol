// SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.8.9;

import "forge-std/console.sol";
import {BaseTest} from "./TestBase.t.sol";
import {GarlicPress} from "../src/GarlicPress.sol"; 
import {GarlicBulb} from "../src/GarlicBulb.sol";
import {MockReceiverContract} from "./mocks/MockReceiverContract.sol";

contract GarlicPressTest is BaseTest {
    GarlicPress public garlicPress;
    address public garlicBulbImplementation;

    function setUp() public override {
        garlicBulbImplementation = address(new GarlicBulb());
        GarlicBulb(garlicBulbImplementation).__GarlicBulb_init(address(this), address(this));

        garlicPress = new GarlicPress(garlicBulbImplementation);
    }

    function testDeployment() public {
        assertEq(address(garlicPress.garlicBulbImplementation()), garlicBulbImplementation);
    }

    function testClone_appSignerAssigned(address signer, address badAddress) public {
        vm.assume(badAddress != signer);
        assumeAddressNotBadAddress(signer);
        assumeAddressNotBadAddress(badAddress);
        bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this)))));
        address garlicBulb = garlicPress.cloneGarlicBulb(address(this), address(this), salt);
        assertEq(GarlicBulb(garlicBulb).signer(), address(this));
        assertEq(GarlicBulb(garlicBulb).owner(), address(this));
        
        assertEq(GarlicBulb(garlicBulb).signer(), address(this));
        assert(GarlicBulb(garlicBulb).signer() != badAddress);
    }

    function testCloneAndReinitialize(address badAddress) public {
        vm.assume(badAddress != address(this));
        bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this)))));
        address garlicBulb = garlicPress.cloneGarlicBulb(address(this), address(this), salt);

        address signerAddress = GarlicBulb(garlicBulb).signer();
        
        assertEq(signerAddress, address(this));

        vm.expectRevert("Initializable: contract is already initialized");
        GarlicBulb(garlicBulb).__GarlicBulb_init(badAddress, badAddress);

        signerAddress = GarlicBulb(garlicBulb).signer();

        assertEq(signerAddress, address(this));
    }

    function testForwardCall_base_revert_withSig(address sender) public {
        vm.assume(sender != address(this) && sender != address(0));
        bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this)))));
        address garlicBulb = garlicPress.cloneGarlicBulb(address(this), address(0), salt);

        MockReceiverContract mockReceiver = new MockReceiverContract(address(garlicPress));

        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithRevert.selector, sender);

        vm.startPrank(sender);
        GarlicBulb(garlicBulb).forwardCall(address(mockReceiver), message, GarlicBulb.SignatureECDSA(0, bytes32(0), bytes32(0)));
    }

    function testForwardCall_base_revert_noSig(address sender) public {
        vm.assume(sender != address(this) && sender != address(0));
        bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this)))));
        address garlicBulb = garlicPress.cloneGarlicBulb(address(this), address(0), salt);

        MockReceiverContract mockReceiver = new MockReceiverContract(address(garlicPress));

        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithRevert.selector, sender);
        vm.deal(sender, 1 ether);

        vm.startPrank(sender);
        GarlicBulb(garlicBulb).forwardCall(address(mockReceiver), message);
    }

    function testForwardCall_base_return(address sender) public {
        vm.assume(sender != address(this) && sender != address(0));
        bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this)))));
        address garlicBulb = garlicPress.cloneGarlicBulb(address(this), address(0), salt);

        MockReceiverContract mockReceiver = new MockReceiverContract(address(garlicPress));

        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithReturnValue.selector, sender);

        vm.startPrank(sender);
        bytes memory retVal = GarlicBulb(garlicBulb).forwardCall(address(mockReceiver), message, GarlicBulb.SignatureECDSA(0, bytes32(0), bytes32(0)));

        assertEq(abi.decode(retVal, (bool)), true);

        vm.stopPrank();

        retVal = GarlicBulb(garlicBulb).forwardCall(address(mockReceiver), message, GarlicBulb.SignatureECDSA(0, bytes32(0), bytes32(0)));

        assertEq(abi.decode(retVal, (bool)), false);
    }

    function testForwardCall_nonMatchingSender_revert(address sender) public {
        vm.assume(sender != address(this) && sender != address(0));
        bytes32 salt = bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this)))));
        address garlicBulb = garlicPress.cloneGarlicBulb(address(this), address(0), salt);

        MockReceiverContract mockReceiver = new MockReceiverContract(address(garlicPress));

        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithRevert.selector, address(this));

        vm.startPrank(sender);
        vm.expectRevert(abi.encodeWithSelector(GarlicBulb.GarlicBulb__ExternalContractCallReverted.selector, abi.encodeWithSelector(bytes4(keccak256("Error(string)")), bytes("MockReceiverContract__SenderDoesNotMatch"))));
        GarlicBulb(garlicBulb).forwardCall(address(mockReceiver), message, GarlicBulb.SignatureECDSA(0, bytes32(0), bytes32(0)));
    }
}