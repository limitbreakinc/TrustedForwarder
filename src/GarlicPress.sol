// SPDX-License-Identifier: MIT
pragma solidity <= 0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";

contract GarlicPress {

    error GarlicPress__GarlicBulbInitFailed(address admin, address appSigner);

    event GarlicBulbCreated(address indexed garlicBulb);

    // keccak256("__GarlicBulb_init(address,address)")
    bytes4 constant private INIT_SELECTOR = 0x6f796a3d;
    address immutable public garlicBulbImplementation;

    mapping(address => bool) public forwarders;

    constructor(address garlicBulbImplementation_) {
        garlicBulbImplementation = garlicBulbImplementation_;
    }

    /**
     * @notice Returns true if the sender is a trusted forwarder, false otherwise.
     * @notice Addresses are added to the `forwarders` mapping when they are cloned via the `cloneGarlicBulb` function.
     *
     * @dev    This function allows for the GarlicBulb contracts to be used as trusted forwarders within the GarlicERC2771Context mixin.
     * 
     * @param sender The address to check.
     * @return True if the sender is a trusted forwarder, false otherwise.
     */
    function isTrustedForwarder(address sender) external view returns (bool) {
        return forwarders[sender];
    }

    /**
     * @notice Clones the GarlicBulb implementation and initializes it.
     *
     * @dev    To prevent hostile deployments, we hash the sender's address with the salt to create the final salt.
     * @dev    This prevents the mining of specific contract addresses for deterministic deployments, but still allows for
     * @dev    a canonical address to be created for each sender.
     *
     * @param admin           The address to assign the admin role to.
     * @param appSigner       The address to assign the app signer role to. This will be ignored if `enableAppSigner` is false.
     * @param salt            The salt to use for the deterministic deployment.  This is hashed with the sender's address to create the final salt.
     *
     * @return The address of the newly created GarlicBulb contract.
     */
    function cloneGarlicBulb(address admin, address appSigner, bytes32 salt) external returns (address) {
        address garlicBulb = Clones.cloneDeterministic(garlicBulbImplementation, keccak256(abi.encode(msg.sender, salt)));

        (bool success, ) = garlicBulb.call(abi.encodeWithSelector(INIT_SELECTOR, admin, appSigner));
        if (!success) {
            revert GarlicPress__GarlicBulbInitFailed(admin, appSigner);
        }
        forwarders[garlicBulb] = true;

        emit GarlicBulbCreated(garlicBulb);

        return garlicBulb;
    }
}
