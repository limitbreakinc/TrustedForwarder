// SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.8.9;

import "forge-std/console.sol";
import {BaseTest} from "./TestBase.t.sol";
import {TrustedForwarderFactory} from "../src/TrustedForwarderFactory.sol"; 
import {TrustedForwarder} from "../src/TrustedForwarder.sol";
import {MockReceiverContract} from "./mocks/MockReceiverContract.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TrustedForwarderTest is BaseTest {
    function setUp() public override {
        super.setUp();

        TrustedForwarder imp = new TrustedForwarder();
        forwarderImplementation = address(imp);
        imp.__TrustedForwarder_init(address(this), address(this));

        factory = new TrustedForwarderFactory(forwarderImplementation);
        address clone = factory.cloneTrustedForwarder(address(this), address(0), bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this))))));
        forwarder = TrustedForwarder(clone);
        mockReceiver = new MockReceiverContract(address(factory));
    }

    // ===================== OWNER CHECKS =====================
    function testUpdateSigner_NonOwner(address badActor) public {
        vm.assume(badActor != forwarder.owner());
        vm.prank(badActor);
        vm.expectRevert("Ownable: caller is not the owner");
        forwarder.updateSigner(signer);
    }

    function testUpdateSigner_ZeroAddress() public {
        vm.expectRevert(TrustedForwarder.TrustedForwarder__CannotSetAppSignerToZeroAddress.selector);
        forwarder.updateSigner(address(0));
    }

    function testTransferOwnership_NonOwner(address badActor) public {
        vm.assume(badActor != forwarder.owner());
        vm.prank(badActor);
        vm.expectRevert("Ownable: caller is not the owner");
        forwarder.transferOwnership(badActor);
    }

    function testTransferOwnership_base(address newOwner) public {
        vm.assume(newOwner != forwarder.owner());
        vm.assume(newOwner != address(0));

        forwarder.transferOwnership(newOwner);

        assertEq(forwarder.owner(), newOwner);
    }

    function testTransferOwnership_ZeroAddress() public {
        vm.expectRevert("Ownable: new owner is the zero address");
        forwarder.transferOwnership(address(0));

        assertEq(forwarder.owner(), address(this));
    }

    // ===================== SIGNER CHECKS =====================
    function testForwardCall_SignerEnabledNoSignature() public {
        forwarder.updateSigner(signer);

        vm.expectRevert(TrustedForwarder.TrustedForwarder__CannotUseWithoutSignature.selector);
        forwarder.forwardCall(address(mockReceiver), abi.encodeWithSelector(mockReceiver.noReturnData.selector));
    }

    function testForwardCall_InvalidSigner(address sender) public {
        vm.deal(sender, 1 ether);
        (, uint256 badKey) = makeAddrAndKey("badActor");
        forwarder.updateSigner(signer);

        bytes memory message = abi.encodeWithSelector(mockReceiver.getSomeLargeData_Payable.selector);

        forwarder.updateSigner(signer);

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
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(badKey, digest);

        vm.prank(sender);
        vm.expectRevert(TrustedForwarder.TrustedForwarder__SignerNotAuthorized.selector);
        forwarder.forwardCall{value: 1 ether}(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));

    }

    // ===================== EOA RECEIVER CHECKS =====================
    function testForwardCall_EOAReceiver(address destination, bytes memory message) public {
        vm.assume(destination.code.length == 0);
        assumeAddressNotBadAddress(destination);

        vm.expectRevert(bytes4(keccak256("TrustedForwarder__TargetAddressHasNoCode()")));
        forwarder.forwardCall(destination, message);
    }

    function testForwardCall_EOACReceiver_WithMsgValue(address destination, bytes memory message) public {
        vm.deal(address(this), 1 ether);
        vm.assume(destination.code.length == 0);
        assumeAddressNotBadAddress(destination);

        assertEq(address(this).balance, 1 ether);

        vm.expectRevert(bytes4(keccak256("TrustedForwarder__TargetAddressHasNoCode()")));
        forwarder.forwardCall{value: 1 ether}(destination, message);

        assertEq(address(this).balance, 1 ether);
    }

    // ===================== LARGE BYTES RETURNS =====================
    function testForwardCall_WithMsgValue_ReturnLargeValue() public {
        vm.deal(address(this), 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.getSomeLargeData_Payable.selector);

        bytes memory retVal = TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message);
        string memory decodedVal = abi.decode(retVal, (string));
        string memory expectedReturn = "this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.";
        assertEq(decodedVal, expectedReturn);
        assertEq(address(mockReceiver).balance, 1 ether);
    }

    function testForwardCall_WithoutMsgValue_ReturnLargeValue() public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.getSomeLargeData.selector);

        bytes memory retVal = TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message);
        string memory decodedVal = abi.decode(retVal, (string));
        string memory expectedReturn = "this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.";
        assertEq(decodedVal, expectedReturn);
    }
    
    function testForwardCall_WithMsgValue_ReturnLargeValue_WithSigner(address sender) public {
        vm.deal(sender, 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.getSomeLargeData_Payable.selector);

        forwarder.updateSigner(signer);

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
        bytes memory retVal = forwarder.forwardCall{value: 1 ether}(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
        string memory decodedVal = abi.decode(retVal, (string));
        string memory expectedReturn = "this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.";
        assertEq(decodedVal, expectedReturn);
        assertEq(address(mockReceiver).balance, 1 ether);
    }

    function testForwardCall_WithoutMsgValue_ReturnLargeValue_WithSigner(address sender) public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.getSomeLargeData.selector);

        forwarder.updateSigner(signer);

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
        bytes memory retVal = forwarder.forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
        string memory decodedVal = abi.decode(retVal, (string));
        string memory expectedReturn = "this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.this is a really long bytes message we are returning.  It will surely be more than one word, and will need to be put into many many many different slots.";
        assertEq(decodedVal, expectedReturn);
    }

    // ===================== SINGLE WORD BYTES RETURNS =====================
    function testForwardCall_WithMsgValue_ReturnOneWordValue() public {
        vm.deal(address(this), 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.getTheDataBytesReturn_Payable.selector);

        bytes memory retVal = TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message);
        bytes memory decodedVal = abi.decode(retVal, (bytes));
        assertEq(keccak256(decodedVal), keccak256(message));
        assertEq(address(mockReceiver).balance, 1 ether);
    }

    function testForwardCall_WithoutMsgValue_ReturnOneWordValue() public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.getTheDataBytesReturn.selector);

        bytes memory retVal = TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message);
        bytes memory decodedVal = abi.decode(retVal, (bytes));
        assertEq(keccak256(decodedVal), keccak256(message));
    }

    function testForwardCall_WithMsgValue_ReturnOneWordValue_WithSigner(address sender) public {
        vm.deal(sender, 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.getTheDataBytesReturn_Payable.selector);

        forwarder.updateSigner(signer);

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
        bytes memory retVal = forwarder.forwardCall{value: 1 ether}(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
        bytes memory decodedVal = abi.decode(retVal, (bytes));
        assertEq(keccak256(decodedVal), keccak256(message));
        assertEq(address(mockReceiver).balance, 1 ether);
    }

    function testForwardCall_WithoutMsgValue_ReturnOneWordValue_WithSigner(address sender) public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.getTheDataBytesReturn.selector);

        forwarder.updateSigner(signer);

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
        bytes memory retVal = forwarder.forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
        bytes memory decodedVal = abi.decode(retVal, (bytes));
        assertEq(keccak256(decodedVal), keccak256(message));
    }

    // ===================== SINGLE VARIABLE TYPED RETURNS =====================
    function testForwardCall_WithMsgValue_ReturnsSingleTypedVariable(bytes memory payload) public {
        vm.deal(address(this), 2 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.getTheData_Payable.selector, payload);

        bytes memory retVal = TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message);
        bool decodedVal = abi.decode(retVal, (bool));
        assertEq(decodedVal, true);

        // Confirm the msg.data is handled identically for both the forwarder and a direct call to the receiver
        bool retValDirect = MockReceiverContract(mockReceiver).getTheData_Payable{value: 1 ether}(payload);
        assertEq(retValDirect, true);

        assertEq(address(mockReceiver).balance, 2 ether);
    }

    function testForwardCall_WithoutMsgValue_ReturnsSingleTypedVariable(bytes memory payload) public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.getTheData.selector, payload);

        bytes memory retVal = TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message);
        bool decodedVal = abi.decode(retVal, (bool));
        assertEq(decodedVal, true);

        // Confirm the msg.data is handled identically for both the forwarder and a direct call to the receiver
        bool retValDirect = MockReceiverContract(mockReceiver).getTheData(payload);
        assertEq(retValDirect, true);
    }

    function testForwardCall_WithMsgValue_ReturnsSingleTypedVariable_WithSigner(bytes memory payload, address sender) public {
        vm.assume(sender != address(mockReceiver));
        vm.deal(sender, 2 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.getTheData_Payable.selector, payload);

        forwarder.updateSigner(signer);
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
        bytes memory retVal = TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
        bool decodedVal = abi.decode(retVal, (bool));
        assertEq(decodedVal, true);

        // Confirm the msg.data is handled identically for both the forwarder and a direct call to the receiver
        bool retValDirect = MockReceiverContract(mockReceiver).getTheData_Payable{value: 1 ether}(payload);
        assertEq(retValDirect, true);

        assertEq(address(mockReceiver).balance, 2 ether);
    }

    function testForwardCall_WithoutMsgValue_ReturnsSingleTypedVariable_WithSigner(bytes memory payload, address sender) public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.getTheData.selector, payload);

        forwarder.updateSigner(signer);
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
        bytes memory retVal = TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
        bool decodedVal = abi.decode(retVal, (bool));
        assertEq(decodedVal, true);

        // Confirm the msg.data is handled identically for both the forwarder and a direct call to the receiver
        bool retValDirect = MockReceiverContract(mockReceiver).getTheData(payload);
        assertEq(retValDirect, true);
    }

    // ===================== MULTI VARIABLE TYPED RETURNS =====================
    function testForwardCall_WithMsgValue_ReturnsMultipleTypedVariables() public {
        vm.deal(address(this), 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.getMultipleValuesReturned_Payable.selector);

        bytes memory retVal = TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message);
        (uint256 number, string memory str, bool boolean, uint8 smolnum, MockReceiverContract.ExampleReturn memory example) = abi.decode(retVal, (uint256, string, bool, uint8, MockReceiverContract.ExampleReturn));
        assertEq(number, 999);
        assertEq(str, "hello world");
        assertEq(boolean, true);
        assertEq(smolnum, uint8(5));
        assertEq(example.uintValue, 222);
        assertEq(example.stringValue, "hello world, but in the struct");
        assertEq(example.boolValue, false);
        assertEq(example.uint8Value, uint8(1));

        assertEq(address(mockReceiver).balance, 1 ether);
    }

    function testForwardCall_WithoutMsgValue_ReturnsMultipleTypedVariables() public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.getMultipleValuesReturned.selector);

        bytes memory retVal = TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message);
        (uint256 number, string memory str, bool boolean, uint8 smolnum, MockReceiverContract.ExampleReturn memory example) = abi.decode(retVal, (uint256, string, bool, uint8, MockReceiverContract.ExampleReturn));
        assertEq(number, 999);
        assertEq(str, "hello world");
        assertEq(boolean, true);
        assertEq(smolnum, uint8(5));
        assertEq(example.uintValue, 222);
        assertEq(example.stringValue, "hello world, but in the struct");
        assertEq(example.boolValue, false);
        assertEq(example.uint8Value, uint8(1));
    }

    function testForwardCall_WithMsgValue_ReturnsMultipleTypedVariables_WithSigner(address sender) public {
        vm.deal(sender, 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.getMultipleValuesReturned_Payable.selector);

        forwarder.updateSigner(signer);
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
        bytes memory retVal = TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
        (uint256 number, string memory str, bool boolean, uint8 smolnum, MockReceiverContract.ExampleReturn memory example) = abi.decode(retVal, (uint256, string, bool, uint8, MockReceiverContract.ExampleReturn));
        assertEq(number, 999);
        assertEq(str, "hello world");
        assertEq(boolean, true);
        assertEq(smolnum, uint8(5));
        assertEq(example.uintValue, 222);
        assertEq(example.stringValue, "hello world, but in the struct");
    }

    function testForwardCall_WithoutMsgValue_ReturnsMultipleTypedVariables_WithSigner(address sender) public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.getMultipleValuesReturned.selector);

        forwarder.updateSigner(signer);
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
        bytes memory retVal = TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
        (uint256 number, string memory str, bool boolean, uint8 smolnum, MockReceiverContract.ExampleReturn memory example) = abi.decode(retVal, (uint256, string, bool, uint8, MockReceiverContract.ExampleReturn));
        assertEq(number, 999);
        assertEq(str, "hello world");
        assertEq(boolean, true);
        assertEq(smolnum, uint8(5));
        assertEq(example.uintValue, 222);
        assertEq(example.stringValue, "hello world, but in the struct");
    }

    // ===================== EMPTY RETURNS =====================
    function testForwardCall_WithMsgValue_ReturnsNoValue() public {
        vm.deal(address(this), 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.noReturnData_Payable.selector);

        bytes memory retVal = TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message);
        assertEq(retVal.length, 0);

        assertEq(address(mockReceiver).balance, 1 ether);
    }

    function testForwardCall_WithoutMsgValue_ReturnsNoValue() public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.noReturnData.selector);

        bytes memory retVal = TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message);
        assertEq(retVal.length, 0);
    }

    function testForwardCall_WithMsgValue_ReturnsNoValue_WithSigner(address sender) public {
        vm.deal(sender, 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.noReturnData_Payable.selector);

        forwarder.updateSigner(signer);
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
        bytes memory retVal = TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
        assertEq(retVal.length, 0);

        assertEq(address(mockReceiver).balance, 1 ether);
    }

    function testForwardCall_WithoutMsgValue_ReturnsNoValue_WithSigner(address sender) public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.noReturnData.selector);

        forwarder.updateSigner(signer);
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
        bytes memory retVal = TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
        assertEq(retVal.length, 0);
    }

    // ===================== DESTINATION CONFIRMS MSG.SENDER APPENDED TO CALLDATA =====================
    function testForwardCall_WithMsgValue_DestinationConfirmsSenderAppendedToCallData(address sender) public {
        vm.deal(sender, 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithReturnValue_Payable.selector, sender);

        vm.prank(sender);
        bytes memory retVal = TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message);
        bool decodedVal = abi.decode(retVal, (bool));
        assertEq(decodedVal, true);

        assertEq(address(mockReceiver).balance, 1 ether);
    }

    function testForwardCall_WithoutMsgValue_DestinationConfirmsSenderAppendedToCallData(address sender) public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithReturnValue.selector, sender);

        vm.prank(sender);
        bytes memory retVal = TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message);
        bool decodedVal = abi.decode(retVal, (bool));
        assertEq(decodedVal, true);
    }

    function testForwardCall_WithMsgValue_DestinationConfirmsSenderAppendedToCallData_WithSigner(address sender) public {
        vm.deal(sender, 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithReturnValue_Payable.selector, sender);

        forwarder.updateSigner(signer);
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
        bytes memory retVal = TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
        bool decodedVal = abi.decode(retVal, (bool));
        assertEq(decodedVal, true);

        assertEq(address(mockReceiver).balance, 1 ether);
    }

    function testForwardCall_WithoutMsgValue_DestinationConfirmsSenderAppendedToCallData_WithSigner(address sender) public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithReturnValue.selector, sender);

        forwarder.updateSigner(signer);
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
        bytes memory retVal = TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
        bool decodedVal = abi.decode(retVal, (bool));
        assertEq(decodedVal, true);
    }

    // ===================== DESTINATION STORES DATA =====================
    function testForwardCall_WithMsgValue_DestinationStoresData(address sender, uint256 data1, string calldata data2, uint8 data3, bool data4) public {
        vm.deal(sender, 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.storeTheData_Payable.selector, data1, data2, data3, data4);

        vm.prank(sender);
        TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message);

        assertEq(mockReceiver.uint256Value(), data1);
        assertEq(mockReceiver.stringValue(), data2);
        assertEq(mockReceiver.uint8Value(), data3);
        assertEq(mockReceiver.boolValue(), data4);

        assertEq(address(mockReceiver).balance, 1 ether);
    }

    function testForwardCall_WithoutMsgValue_DestinationStoresData(address sender, uint256 data1, string calldata data2, uint8 data3, bool data4) public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.storeTheData.selector, data1, data2, data3, data4);

        vm.prank(sender);
        TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message);

        assertEq(mockReceiver.uint256Value(), data1);
        assertEq(mockReceiver.stringValue(), data2);
        assertEq(mockReceiver.uint8Value(), data3);
        assertEq(mockReceiver.boolValue(), data4);
    }

    function testForwardCall_WithMsgValue_DestinationStoresData_WithSigner(address sender, uint256 data1, string calldata data2, uint8 data3, bool data4) public {
        vm.deal(sender, 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.storeTheData_Payable.selector, data1, data2, data3, data4);

        forwarder.updateSigner(signer);
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
        TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));

        assertEq(mockReceiver.uint256Value(), data1);
        assertEq(mockReceiver.stringValue(), data2);
        assertEq(mockReceiver.uint8Value(), data3);
        assertEq(mockReceiver.boolValue(), data4);

        assertEq(address(mockReceiver).balance, 1 ether);
    }

    function testForwardCall_WithoutMsgValue_DestinationStoresData_WithSigner(address sender, uint256 data1, string calldata data2, uint8 data3, bool data4) public {
        bytes memory message = abi.encodeWithSelector(mockReceiver.storeTheData.selector, data1, data2, data3, data4);

        forwarder.updateSigner(signer);
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
        TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));

        assertEq(mockReceiver.uint256Value(), data1);
        assertEq(mockReceiver.stringValue(), data2);
        assertEq(mockReceiver.uint8Value(), data3);
        assertEq(mockReceiver.boolValue(), data4);
    }

    // ===================== DESTINATION REVERTS =====================
    function testForwardCall_WithMsgValue_DestinationReverts(address sender) public {
        vm.assume(sender != address(this));
        vm.deal(address(this), 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithRevert_Payable.selector, sender);

        vm.expectRevert("MockReceiverContract__SenderDoesNotMatch");
        TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message);

        assertEq(address(mockReceiver).balance, 0 ether);
        assertEq(address(this).balance, 1 ether);
    }

    function testForwardCall_WithoutMsgValue_DestinationReverts(address sender) public {
        vm.assume(sender != address(this));
        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithRevert.selector, sender);

        vm.expectRevert("MockReceiverContract__SenderDoesNotMatch");
        TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message);
    }

    function testForwardCall_WithMsgValue_DestinationReverts_WithSigner(address sender) public {
        vm.assume(sender != address(this));
        vm.deal(address(this), 1 ether);
        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithRevert_Payable.selector, sender);

        forwarder.updateSigner(signer);
        bytes32 digest = ECDSA.toTypedDataHash(
            forwarder.domainSeparatorV4(), 
            keccak256(
                abi.encode(
                    forwarder.APP_SIGNER_TYPEHASH(), 
                    keccak256(message),
                    address(mockReceiver),
                    address(this)
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);
        
        vm.expectRevert("MockReceiverContract__SenderDoesNotMatch");
        TrustedForwarder(forwarder).forwardCall{value: 1 ether}(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));

        assertEq(address(mockReceiver).balance, 0 ether);
        assertEq(address(this).balance, 1 ether);
    }

    function testForwardCall_WithoutMsgValue_DestinationReverts_WithSigner(address sender) public {
        vm.assume(sender != address(this));
        bytes memory message = abi.encodeWithSelector(mockReceiver.findTheSenderWithRevert.selector, sender);

        forwarder.updateSigner(signer);
        bytes32 digest = ECDSA.toTypedDataHash(
            forwarder.domainSeparatorV4(), 
            keccak256(
                abi.encode(
                    forwarder.APP_SIGNER_TYPEHASH(), 
                    keccak256(message),
                    address(mockReceiver),
                    address(this)
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);
        
        vm.expectRevert("MockReceiverContract__SenderDoesNotMatch");
        TrustedForwarder(forwarder).forwardCall(address(mockReceiver), message, TrustedForwarder.SignatureECDSA(v, r, s));
    }
}