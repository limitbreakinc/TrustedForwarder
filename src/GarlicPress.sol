// SPDX-License-Identifier: MIT
pragma solidity <= 0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";

contract GarlicPress {

    error GarlicPress__GarlicBulbInitFailed(address admin, bool enableAppSigner, address appSigner);

    event GarlicBulbCreated(address indexed garlicBulb);

    // keccak256("__GarlicBulb_init(address admin,bool enableAppSigner,address appSigner)")
    bytes4 constant private INIT_SELECTOR = 0x7ba9107d;
    address immutable public garlicBulbImplementation;

    mapping(address => bool) public forwarders;

    constructor(address garlicBulbImplementation_) {
        garlicBulbImplementation = garlicBulbImplementation_;
    }

    function isTrustedForwarder(address sender) external view returns (bool) {
        return forwarders[sender];
    }

    function cloneGarlicBulb(address admin, bool enableAppSigner, address appSigner) external returns (address) {
        address garlicBulb = Clones.clone(garlicBulbImplementation);
        (bool success, ) = garlicBulb.call(abi.encodeWithSelector(INIT_SELECTOR, admin, enableAppSigner, appSigner));
        if (!success) {
            revert GarlicPress__GarlicBulbInitFailed(admin, enableAppSigner, appSigner);
        }
        forwarders[garlicBulb] = true;

        emit GarlicBulbCreated(garlicBulb);

        return garlicBulb;
    }
}
