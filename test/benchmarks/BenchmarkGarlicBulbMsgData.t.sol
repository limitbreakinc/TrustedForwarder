// SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.8.9;

import {Test, console2} from "forge-std/Test.sol";
import {GarlicPress} from "src/GarlicPress.sol"; 
import {GarlicBulb} from "src/GarlicBulb.sol";
import {MockReceiverContract} from "../mocks/MockReceiverContract.sol";

contract BenchmarkGarlicBulb is Test {
    GarlicPress public garlicPress;
    address public garlicBulbImplementation;
    GarlicBulb public garlicBulb;
    MockReceiverContract public mockReceiver;

    uint256 signerKey;
    address signerAddress;

    function setUp() public {
        garlicBulbImplementation = address(new GarlicBulb());
        GarlicBulb(garlicBulbImplementation).__GarlicBulb_init(address(this), address(this));

        garlicPress = new GarlicPress(garlicBulbImplementation);
        address clone = garlicPress.cloneGarlicBulb(address(this), address(0), bytes32(uint256(keccak256(abi.encodePacked(address(this), address(this))))));
        garlicBulb = GarlicBulb(clone);

        mockReceiver = new MockReceiverContract(address(garlicPress));
    }

    function testForwardCall_msgData(bytes calldata testData) public {
        vm.assume(testData.length > 0);
        bytes memory message = abi.encodeWithSelector(mockReceiver.getTheData.selector, testData);

        bytes memory retVal = garlicBulb.forwardCall(address(mockReceiver), message, GarlicBulb.SignatureECDSA(0, bytes32(0), bytes32(0)));
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