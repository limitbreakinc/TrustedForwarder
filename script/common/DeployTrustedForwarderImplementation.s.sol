// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "src/TrustedForwarder.sol";

contract DeployTrustedForwarderImplementation is Script {
    function run() public {
        bytes32 saltValue = bytes32(vm.envUint("SALT_TRUSTED_FORWARDER_IMPLEMENTATION"));
        address expectedAddress = vm.envAddress("EXPECTED_TRUSTED_FORWARDER_IMPLEMENTATION_ADDRESS");

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        TrustedForwarder forwarder = new TrustedForwarder{salt: saltValue}();
        vm.stopBroadcast();

        console.log("Creator Trusted Forwarder Implementation: ", address(forwarder));

        if (expectedAddress != address(forwarder)) {
            revert("Unexpected deploy address");
        }
    }
}