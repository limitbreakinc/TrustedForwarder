// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'forge-std/StdCheats.sol';
import 'forge-std/StdAssertions.sol';
import 'forge-std/StdUtils.sol';
import {TestBase} from 'forge-std/Base.sol';

contract BaseTest is TestBase, StdAssertions, StdCheats, StdUtils {

    uint256 adminKey;
    uint256 aliceKey;
    uint256 bobKey;
    uint256 carolKey;
    uint256 signerKey;

    address admin;
    address alice;
    address bob;
    address carol;
    address signer;

    function setUp() public virtual {
        (admin, adminKey) = makeAddrAndKey("admin");
        (alice, aliceKey) = makeAddrAndKey("alice");
        (bob, bobKey) = makeAddrAndKey("bob");
        (carol, carolKey) = makeAddrAndKey("carol");
        (signer, signerKey) = makeAddrAndKey("signer");
    }

    function assumeAddressNotBadAddress(address addr) internal {
        assumeAddressIsNot(addr, AddressType.ZeroAddress, AddressType.Precompile, AddressType.ForgeAddress);
    }
}