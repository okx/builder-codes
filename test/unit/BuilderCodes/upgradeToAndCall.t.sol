// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC1967} from "@openzeppelin/contracts/interfaces/IERC1967.sol";

import {BuilderCodes} from "../../../src/BuilderCodes.sol";
import {BuilderCodesTest} from "../../lib/BuilderCodesTest.sol";
import {MockBuilderCodesV2} from "../../lib/mocks/MockBuilderCodesV2.sol";

/// @notice Unit tests for BuilderCodes.upgradeToAndCall
contract UpgradeToAndCallTest is BuilderCodesTest {
    /// @notice Test that upgradeToAndCall reverts when caller is not the owner
    function test_upgradeToAndCall_revert_notOwner() public {
        address nonOwner = address(0x123);
        address newImplementation = address(new MockBuilderCodesV2());

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        builderCodes.upgradeToAndCall(newImplementation, "");
    }

    /// @notice Test that upgradeToAndCall successfully updates the implementation
    function test_upgradeToAndCall_success_updatesImplementation() public {
        address newImplementation = address(new MockBuilderCodesV2());

        vm.prank(owner);
        builderCodes.upgradeToAndCall(newImplementation, "");

        // Verify the upgrade worked by testing storage preservation
        assertEq(builderCodes.owner(), owner);
        assertTrue(builderCodes.hasRole(builderCodes.REGISTER_ROLE(), registrar));
    }

    /// @notice Test that upgradeToAndCall succeeds without default slot ordering collision
    function test_upgradeToAndCall_success_noDefaultSlotOrderingCollision() public {
        // Register a code before upgrade to test storage preservation
        address testPayoutAddress = address(0x456);

        vm.prank(registrar);
        string memory testCode = builderCodes.register(owner, testPayoutAddress);

        // Store original data
        address originalOwnerOfCode = builderCodes.ownerOf(builderCodes.toTokenId(testCode));
        address originalPayoutAddress = builderCodes.payoutAddress(testCode);

        // Perform upgrade
        address newImplementation = address(new MockBuilderCodesV2());
        vm.prank(owner);
        builderCodes.upgradeToAndCall(newImplementation, "");

        // Verify storage is preserved (no collision)
        assertEq(builderCodes.ownerOf(builderCodes.toTokenId(testCode)), originalOwnerOfCode);
        assertEq(builderCodes.payoutAddress(testCode), originalPayoutAddress);
        assertTrue(builderCodes.isRegistered(testCode));
    }

    /// @notice Test that upgradeToAndCall emits the ERC1967 Upgraded event
    function test_upgradeToAndCall_success_emitsERC1967Upgraded() public {
        address newImplementation = address(new MockBuilderCodesV2());

        vm.expectEmit(true, false, false, false);
        emit IERC1967.Upgraded(newImplementation);

        vm.prank(owner);
        builderCodes.upgradeToAndCall(newImplementation, "");
    }
}
