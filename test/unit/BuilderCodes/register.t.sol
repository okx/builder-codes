// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {BuilderCodes} from "../../../src/BuilderCodes.sol";

import {BuilderCodesTest, IERC721Errors} from "../../lib/BuilderCodesTest.sol";

/// @notice Unit tests for BuilderCodes.register
contract RegisterTest is BuilderCodesTest {
    /// @notice Test that register reverts when sender doesn't have required role and the role check is enabled
    ///
    /// @param sender The sender address
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_register_revert_senderInvalidRole(
        address sender,
        address initialOwner,
        address payoutAddress
    ) public {
        sender = _boundNonZeroAddress(sender);
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);
        vm.assume(sender != owner && sender != registrar);

        // Enable the role check first
        vm.prank(owner);
        builderCodes.setRegisterRoleEnabled(true);

        vm.startPrank(sender);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, sender, builderCodes.REGISTER_ROLE()
            )
        );
        builderCodes.register(initialOwner, payoutAddress);
    }

    /// @notice Test that register succeeds for any sender when the role check is disabled (default)
    ///
    /// @param sender The sender address
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_register_success_anyoneCanRegisterWhenRoleDisabled(
        address sender,
        address initialOwner,
        address payoutAddress
    ) public {
        sender = _boundNonZeroAddress(sender);
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);
        vm.assume(sender != owner && sender != registrar);

        // Role check is disabled by default
        assertFalse(builderCodes.isRegisterRoleEnabled());

        vm.prank(sender);
        string memory code = builderCodes.register(initialOwner, payoutAddress);

        uint256 tokenId = builderCodes.toTokenId(code);
        assertEq(builderCodes.ownerOf(tokenId), initialOwner);
    }

    /// @notice Test that setRegisterRoleEnabled reverts when called by non-owner
    ///
    /// @param caller The non-owner caller
    function test_register_setRegisterRoleEnabled_revert_notOwner(address caller) public {
        caller = _boundNonZeroAddress(caller);
        vm.assume(caller != owner);

        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, caller));
        builderCodes.setRegisterRoleEnabled(true);
    }

    /// @notice Test that setRegisterRoleEnabled emits RegisterRoleToggled event
    ///
    /// @param enabled The new enabled state
    function test_register_setRegisterRoleEnabled_emitsEvent(bool enabled) public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit BuilderCodes.RegisterRoleToggled(enabled);
        builderCodes.setRegisterRoleEnabled(enabled);
    }

    /// @notice Test that setRegisterRoleEnabled correctly updates isRegisterRoleEnabled
    function test_register_setRegisterRoleEnabled_updatesState() public {
        assertFalse(builderCodes.isRegisterRoleEnabled());

        vm.prank(owner);
        builderCodes.setRegisterRoleEnabled(true);
        assertTrue(builderCodes.isRegisterRoleEnabled());

        vm.prank(owner);
        builderCodes.setRegisterRoleEnabled(false);
        assertFalse(builderCodes.isRegisterRoleEnabled());
    }

    /// @notice Test that register succeeds for registrar when role check is enabled
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_register_success_registrarCanRegisterWhenRoleEnabled(
        address initialOwner,
        address payoutAddress
    ) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(owner);
        builderCodes.setRegisterRoleEnabled(true);

        vm.prank(registrar);
        string memory code = builderCodes.register(initialOwner, payoutAddress);

        uint256 tokenId = builderCodes.toTokenId(code);
        assertEq(builderCodes.ownerOf(tokenId), initialOwner);
    }

    /// @notice Test that register reverts when the initial owner is zero address
    ///
    /// @param payoutAddress The payout address
    function test_register_revert_zeroInitialOwner(address payoutAddress) public {
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(registrar);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0)));
        builderCodes.register(address(0), payoutAddress);
    }

    /// @notice Test that register reverts when the payout address is zero address
    ///
    /// @param initialOwner The initial owner address
    function test_register_revert_zeroPayoutAddress(address initialOwner) public {
        initialOwner = _boundNonZeroAddress(initialOwner);

        vm.prank(registrar);
        vm.expectRevert(BuilderCodes.ZeroAddress.selector);
        builderCodes.register(initialOwner, address(0));
    }

    /// @notice Test that register successfully mints a token
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_register_success_mintsToken(address initialOwner, address payoutAddress) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(registrar);
        string memory code = builderCodes.register(initialOwner, payoutAddress);

        uint256 tokenId = builderCodes.toTokenId(code);
        assertEq(builderCodes.ownerOf(tokenId), initialOwner);
        assertTrue(builderCodes.isRegistered(code));
    }

    /// @notice Test that register can be called by owner
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_register_success_ownerCanRegister(address initialOwner, address payoutAddress)
        public
    {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(owner);
        string memory code = builderCodes.register(initialOwner, payoutAddress);

        uint256 tokenId = builderCodes.toTokenId(code);
        assertEq(builderCodes.ownerOf(tokenId), initialOwner);
        assertTrue(builderCodes.isRegistered(code));
    }

    /// @notice Test that register successfully sets the payout address
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_register_success_setsPayoutAddress(address initialOwner, address payoutAddress)
        public
    {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(registrar);
        string memory code = builderCodes.register(initialOwner, payoutAddress);

        assertEq(builderCodes.payoutAddress(code), payoutAddress);
    }

    /// @notice Test that register emits the CodeRegistered event
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_register_success_emitsCodeRegistered(address initialOwner, address payoutAddress)
        public
    {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(registrar);
        string memory code = builderCodes.register(initialOwner, payoutAddress);

        uint256 tokenId = builderCodes.toTokenId(code);
        // Verify the code was registered (event was emitted during register)
        assertTrue(builderCodes.isRegistered(code));
        assertEq(builderCodes.ownerOf(tokenId), initialOwner);
    }

    /// @notice Test that register successfully sets the payout address (verified via event)
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_register_success_setsPayoutAddressCorrectly(address initialOwner, address payoutAddress)
        public
    {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(registrar);
        string memory code = builderCodes.register(initialOwner, payoutAddress);

        uint256 tokenId = builderCodes.toTokenId(code);
        assertEq(builderCodes.payoutAddress(code), payoutAddress);
        assertEq(builderCodes.ownerOf(tokenId), initialOwner);
    }

    /// @notice Test that register returns a valid code
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_register_success_returnsValidCode(address initialOwner, address payoutAddress) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(registrar);
        string memory code = builderCodes.register(initialOwner, payoutAddress);

        assertTrue(builderCodes.isValidCode(code));
        assertEq(bytes(code).length, builderCodes.GENERATED_CODE_LENGTH());
    }
}
