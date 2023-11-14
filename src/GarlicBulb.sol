// SPDX-License-Identifier: MIT
pragma solidity <=0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./GarlicERC2771Context.sol";

/**
 * @title  GarlicBulb
 * @author Limit Break, Inc.
 * @notice GarlicBulb is a generic message forwarder, which allows you to relay transactions to any contract and preserve the original sender.
 *         The processor acts as a trusted proxy, which can be a way to limit interactions with your contract, or enforce certain conditions.
 */
contract GarlicBulb is AccessControl, EIP712, Initializable {
    error GarlicBulb__CannotSetAdminToZeroAddress();
    error GarlicBulb__CannotSetAppSignerToZeroAddress();
    error GarlicBulb__CannotTransferAdminRoleToSelf();
    error GarlicBulb__CannotTransferAdminRoleToZeroAddress();
    error GarlicBulb__ExpiredSignature();
    error GarlicBulb__ExternalContractCallReverted();
    error GarlicBulb__InvalidSignature();
    error GarlicBulb__OnlyAdmin();
    error GarlicBulb__SignerNotAuthorized();
    error GarlicBulb__TargetAddressHasNoCode();

    struct SignatureECDSA {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    bytes32 public constant APP_SIGNER_ROLE = keccak256("APP_SIGNER_ROLE");
    // keccak256("AppSigner(bytes32 messageHash,address target,address sender)")
    bytes32 public constant APP_SIGNER_TYPEHASH = 0xc83d02443cc9e12c5d2faae8a9a36bf0112f5b4a8cce23c9277a0c68bf638762;

    bool public appSignerEnabled;

    modifier onlyAdmin() {
        _requireIsAdmin();
        _;
    }

    constructor() EIP712("GarlicBulb", "1") {}

    /**
     * @notice Initializes the GarlicBulb contract.
     *
     * @dev    This should be called atomically with the clone of the contract to prevent bad actors from calling it.
     * @dev    - Throws if the contract is already initialized
     *
     * @param admin           The address to assign the admin role to.
     * @param enableAppSigner True to enable the app signer role, false otherwise.
     * @param appSigner       The address to assign the app signer role to. This will be ignored if `enableAppSigner` is false.
     */
    function __GarlicBulb_init(address admin, bool enableAppSigner, address appSigner) external initializer {
        if (admin == address(0)) {
            revert GarlicBulb__CannotSetAdminToZeroAddress();
        }
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        if (enableAppSigner) {
            if (appSigner == address(0)) {
                revert GarlicBulb__CannotSetAppSignerToZeroAddress();
            }
            _setupRole(APP_SIGNER_ROLE, appSigner);
            appSignerEnabled = true;
        }
    }

    /**
     * @notice Forwards a message to a target contract, preserving the original sender.
     * @notice If `appSignerEnabled` is true, the call must include a signature from an address with the app signer role.
     *
     * @dev    - Throws if the target contract reverts.
     * @dev    - Throws if the target address has no code.
     * @dev    - Throws if `appSignerEnabled` is true and the signed message does not
     *
     * @param target    The address of the contract to forward the message to.
     * @param message   The calldata to forward.
     * @param signature The signature of the message.
     *
     * @return returnData The return data of the call to the target contract.
     */
    function forwardCall(address target, bytes calldata message, SignatureECDSA calldata signature)
        external
        returns (bytes memory returnData)
    {
        if (appSignerEnabled) {
            if (
                !hasRole(
                    APP_SIGNER_ROLE,
                    _ecdsaRecover(
                        _hashTypedDataV4(
                            keccak256(abi.encode(APP_SIGNER_TYPEHASH, keccak256(message), target, _msgSender()))
                        ),
                        signature.v,
                        signature.r,
                        signature.s
                    )
                )
            ) {
                revert GarlicBulb__SignerNotAuthorized();
            }
        }

        bool success;
        (success, returnData) = target.call(_encodeERC2771Context(message, _msgSender()));

        if (success) {
            if (returnData.length > 0) {
                uint256 targetCodeLength;
                assembly {
                    targetCodeLength := extcodesize(target)
                }
                if (targetCodeLength == 0) {
                    revert GarlicBulb__TargetAddressHasNoCode();
                }
            }
        } else {
            revert GarlicBulb__ExternalContractCallReverted();
        }
    }

    /**
     * @notice Transfers the admin role to a new address.
     *
     * @dev    - Throws if the new admin is the zero address.
     * @dev    - Throws if the new admin is the current admin.
     * @dev    - Throws if the sender is not the admin.
     *
     * @param newAdmin The address to transfer the admin role to.
     */
    function transferAdminRole(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) {
            revert GarlicBulb__CannotTransferAdminRoleToZeroAddress();
        }

        if (newAdmin == _msgSender()) {
            revert GarlicBulb__CannotTransferAdminRoleToSelf();
        }

        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Revokes the admin role from an address.
     *
     * @dev    - Throws if the sender is not the admin.
     *
     * @param admin The address to revoke the admin role from.
     */
    function revokeAdminRole(address admin) external onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @notice Grants the app signer role to an address.
     *
     * @dev    - Throws if the sender is not the admin.
     *
     * @param appSigner The address to grant the app signer role to.
     */
    function grantAppSignerRole(address appSigner) external onlyAdmin {
        grantRole(APP_SIGNER_ROLE, appSigner);
    }

    /**
     * @notice Revokes the app signer role from an address.
     *
     * @dev    - Throws if the sender is not the admin.
     *
     * @param appSigner The address to revoke the app signer role from.
     */
    function revokeAppSignerRole(address appSigner) external onlyAdmin {
        revokeRole(APP_SIGNER_ROLE, appSigner);
    }

    /**
     * @notice Toggles the app signer role.
     *
     * @dev    - Throws if the sender is not the admin.
     */
    function toggleAppSignerEnabled() external onlyAdmin {
        appSignerEnabled = !appSignerEnabled;
    }

    /// @dev appends the msg.sender to the end of the calldata
    function _encodeERC2771Context(bytes calldata _data, address _msgSender) internal pure returns (bytes memory) {
        return abi.encodePacked(_data, _msgSender);
    }

    /**
     * @notice Recovers an ECDSA signature
     *
     * @dev    This function is copied from OpenZeppelin's ECDSA library
     *
     * @param digest The digest to recover
     * @param v      The v component of the signature
     * @param r      The r component of the signature
     * @param s      The s component of the signature
     *
     * @return signer The signer of the digest
     */
    function _ecdsaRecover(bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns (address signer) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert GarlicBulb__InvalidSignature();
        }

        signer = ecrecover(digest, v, r, s);
        if (signer == address(0)) {
            revert GarlicBulb__InvalidSignature();
        }
    }

    /// @dev Throws if called by any account other than the admin.
    function _requireIsAdmin() private view {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert GarlicBulb__OnlyAdmin();
        }
    }
}
