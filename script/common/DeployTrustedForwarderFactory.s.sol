// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "src/TrustedForwarderFactory.sol";

contract DeployTrustedForwarderFactory is Script {
    function run() public {
        bytes32 saltValue = bytes32(vm.envUint("SALT_TRUSTED_FORWARDER_FACTORY"));
        address expectedAddress = vm.envAddress("EXPECTED_TRUSTED_FORWARDER_FACTORY_ADDRESS");
        address implementationAddress = vm.envAddress("EXPECTED_TRUSTED_FORWARDER_IMPLEMENTATION_ADDRESS");

        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        TrustedForwarderFactory factory = new TrustedForwarderFactory{salt: saltValue}(implementationAddress);
        vm.stopBroadcast();

        console.log("Creator Trusted Forwarder Factory: ", address(factory));

        if (expectedAddress != address(factory)) {
            revert("Unexpected deploy address");
        }
    }
}