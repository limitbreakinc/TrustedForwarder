// SPDX-License-Identifier: MIT
pragma solidity <=0.8.9;

import "@openzeppelin//contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console.sol";

/**
 * @title  GarlicBulb
 * @author Limit Break, Inc.
 * @notice GarlicBulb is a generic message forwarder, which allows you to relay transactions to any contract and preserve the original sender.
 *         The processor acts as a trusted proxy, which can be a way to limit interactions with your contract, or enforce certain conditions.
 */
contract GarlicBulb is EIP712, Initializable, Ownable {
    error GarlicBulb__CannotSetAppSignerToZeroAddress();
    error GarlicBulb__CannotSetOwnerToZeroAddress();
    error GarlicBulb__ExternalContractCallReverted(bytes returnData);
    error GarlicBulb__InvalidSignature();
    error GarlicBulb__OnlyOwner();
    error GarlicBulb__SignerNotAuthorized();
    error GarlicBulb__TargetAddressHasNoCode();

    struct SignatureECDSA {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // keccak256("AppSigner(bytes32 messageHash,address target,address sender)")
    bytes32 public constant APP_SIGNER_TYPEHASH = 0xc83d02443cc9e12c5d2faae8a9a36bf0112f5b4a8cce23c9277a0c68bf638762;
    address public signer;

    constructor() EIP712("GarlicBulb", "1") {}

    /**
     * @notice Initializes the GarlicBulb contract.
     *
     * @dev    This should be called atomically with the clone of the contract to prevent bad actors from calling it.
     * @dev    - Throws if the contract is already initialized
     *
     * @param owner           The address to assign the owner role to.
     * @param appSigner       The address to assign the app signer role to. This will be ignored if `enableAppSigner` is false.
     */
    function __GarlicBulb_init(address owner, address appSigner) external initializer {
        if (appSigner != address(0)) {
            signer = appSigner;
        }
        _transferOwnership(owner);
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
        payable
        returns (bytes memory returnData)
    {
        address signerCache = signer;
        if (signerCache != address(0)) {
            if (
                    signerCache != _ecdsaRecover(
                        _hashTypedDataV4(
                            keccak256(abi.encode(APP_SIGNER_TYPEHASH, keccak256(message), target, _msgSender()))
                        ),
                        signature.v,
                        signature.r,
                        signature.s
                    )
            ) {
                revert GarlicBulb__SignerNotAuthorized();
            }
        }

        // TODO: Move call to assembly and handle the return data / revert 
        bool success;
        (success, returnData) = target.call{value: msg.value}(_encodeERC2771Context(message, _msgSender()));
        if (success) {
            if (returnData.length == 0) {
                uint256 targetCodeLength;
                assembly {
                    targetCodeLength := extcodesize(target)
                }
                if (targetCodeLength == 0) {
                    revert GarlicBulb__TargetAddressHasNoCode();
                }
            }
        } else {
            revert GarlicBulb__ExternalContractCallReverted(returnData);
        }
    }

    
    /**
     * @notice Overload of forwardCall that does not require a signature.
     * @notice You should use this in the case that the forwarder does not require a signature to save gas.
     *
     * @dev    - Throws if the target contract reverts.
     * @dev    - Throws if the target address has no code.
     * @dev    - Throws if `appSignerEnabled` is true and the signed message does not
     *
     * @param target    The address of the contract to forward the message to.
     * @param message   The calldata to forward.
     *
     * @return returnData The return data of the call to the target contract.
     */
    function forwardCall(address target, bytes calldata message)
        external
        payable
        returns (bytes memory returnData)
    {
        address signerCache = signer;
        if (signerCache != address(0)) {
            revert();
        }

        bool success;
        (success, returnData) = target.call{value: msg.value}(_encodeERC2771Context(message, msg.sender));
        if (success) {
            if (returnData.length == 0) {
                uint256 targetCodeLength;
                assembly {
                    targetCodeLength := extcodesize(target)
                }
                if (targetCodeLength == 0) {
                    revert GarlicBulb__TargetAddressHasNoCode();
                }
            }
        } else {
            revert GarlicBulb__ExternalContractCallReverted(returnData);
        }
    }

    /**
     * @notice Updates the app signer address. To disable app signing, set signer to address(0).
     *
     * @dev    - Throws if the sender is not the owner.
     *
     * @param signer_ The address to assign the app signer role to.
     */
    function updateSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    /**
     * @notice Returns the domain separator used in the permit signature
     *
     * @return The domain separator
     */
    function domainSeparatorV4() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @dev appends the msg.sender to the end of the calldata
    function _encodeERC2771Context(bytes calldata _data, address _msgSender) internal pure returns (bytes memory encodedData) {
        assembly  {
            // Calculate total length: data.length + 20 bytes for the address
            let totalLength := add(_data.length, 20)

            // Allocate memory for the combined data
            encodedData := mload(0x40)
            mstore(0x40, add(encodedData, add(totalLength, 0x20)))

            // Set the length of the `encodedData`
            mstore(encodedData, totalLength)

            // Copy the `bytes calldata` data
            calldatacopy(add(encodedData, 0x20), _data.offset, _data.length)

            // Append the `address`. Addresses are 20 bytes, stored in the last 20 bytes of a 32-byte word
            mstore(add(add(encodedData, 0x20), _data.length), shl(96, _msgSender))
        }
        //TODO: REMOVE THIS BEFORE PROD - THIS IS FOR TESTING ONLY
        // require(keccak256(encodedData) == keccak256(abi.encodePacked(_data, _msgSender)), "GarlicBulb: encoded data does not match expected value");
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
     * @return recoveredSigner The signer of the digest
     */
    function _ecdsaRecover(bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns (address recoveredSigner) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert GarlicBulb__InvalidSignature();
        }

        recoveredSigner = ecrecover(digest, v, r, s);
        if (recoveredSigner == address(0)) {
            revert GarlicBulb__InvalidSignature();
        }
    }

    /// @dev Override OpenZeppelin's implementation to allow for the owner to be address(0)
    ///      We do this to remove the requirement for more advanced initializer logic
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0xdead));
    }
}



//     function _pushProceeds(address to, uint256 proceeds, uint256 pushPaymentGasLimit_) internal {
    //     bool success;

    //     assembly {
    //         // Transfer the ETH and store if it succeeded or not.
    //         success := call(pushPaymentGasLimit_, to, proceeds, 0, 0, 0, 0)
    //     }

    //     if (!success) {
    //         revert cPort__FailedToTransferProceeds();
    //     }
    // }

    //     modifier delegateCall(address module, bytes4 selector, bytes calldata data) {
    //     assembly {
    //         let ptr := mload(0x40)
    //         mstore(ptr, selector)
    //         calldatacopy(add(ptr,0x04), data.offset, data.length)
    //         mstore(0x40, add(ptr,add(0x04, data.length)))

    //         let result := delegatecall(gas(), module, ptr, add(data.length, 4), 0, 0)
    //         if iszero(result) {
    //             // Call has failed, retrieve the error message and revert
    //             let size := returndatasize()
    //             returndatacopy(0, 0, size)
    //             revert(0, size)
    //         }
    //     }        
    //     _;
    // }

    //     function createPaymentMethodWhitelist(bytes calldata data) external returns (uint32 paymentMethodWhitelistId) {
    //     address module = _modulePaymentSettings;
    //     assembly {
    //         let ptr := mload(0x40)
    //         mstore(ptr, hex"f83116c9")
    //         calldatacopy(add(ptr, 0x04), data.offset, data.length)
    //         mstore(0x40, add(ptr, add(0x04, data.length)))

    //         let result := delegatecall(gas(), module, ptr, add(data.length, 4), 0x00, 0x20)

    //         switch result case 0 {
    //             let size := returndatasize()
    //             returndatacopy(0, 0, size)
    //             revert(0, size)
    //         } default {
    //             return (0x00, 0x20)
    //         }
    //     }
    // }