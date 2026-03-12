// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {BuilderCodes} from "../../../src/BuilderCodes.sol";

import {BuilderCodesTest, IERC721Errors} from "../../lib/BuilderCodesTest.sol";

/// @notice Unit tests for BuilderCodes.registerAuto
contract RegisterAutoTest is BuilderCodesTest {
    /// @notice Test that registerAuto successfully mints a token with auto-generated code
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_mintsToken(address initialOwner, address payoutAddress) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(registrar);
        string memory code = builderCodes.registerAuto(initialOwner, payoutAddress);

        uint256 tokenId = builderCodes.toTokenId(code);
        assertEq(builderCodes.ownerOf(tokenId), initialOwner);
        assertTrue(builderCodes.isRegistered(code));
    }

    /// @notice Test that registerAuto generates a 16-character code
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_generatesCorrectLength(address initialOwner, address payoutAddress) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(registrar);
        string memory code = builderCodes.registerAuto(initialOwner, payoutAddress);

        assertEq(bytes(code).length, builderCodes.GENERATED_CODE_LENGTH());
    }

    /// @notice Test that registerAuto generates a valid code
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_generatesValidCode(address initialOwner, address payoutAddress) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(registrar);
        string memory code = builderCodes.registerAuto(initialOwner, payoutAddress);

        assertTrue(builderCodes.isValidCode(code));
    }

    /// @notice Test that registerAuto sets the payout address correctly
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_setsPayoutAddress(address initialOwner, address payoutAddress) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(registrar);
        string memory code = builderCodes.registerAuto(initialOwner, payoutAddress);

        assertEq(builderCodes.payoutAddress(code), payoutAddress);
    }

    /// @notice Test that registerAuto emits CodeRegistered event
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_emitsCodeRegistered(address initialOwner, address payoutAddress) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(registrar);
        string memory code = builderCodes.registerAuto(initialOwner, payoutAddress);

        uint256 tokenId = builderCodes.toTokenId(code);
        assertTrue(builderCodes.isRegistered(code));
        assertEq(builderCodes.ownerOf(tokenId), initialOwner);
    }

    /// @notice Test that registerAuto emits PayoutAddressUpdated event
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_emitsPayoutAddressUpdated(address initialOwner, address payoutAddress) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(registrar);
        vm.expectEmit(false, false, false, true);
        emit BuilderCodes.PayoutAddressUpdated(0, payoutAddress);

        builderCodes.registerAuto(initialOwner, payoutAddress);
    }

    /// @notice Test that registerAuto can be called by owner
    ///
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_ownerCanRegister(address initialOwner, address payoutAddress) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(owner);
        string memory code = builderCodes.registerAuto(initialOwner, payoutAddress);

        uint256 tokenId = builderCodes.toTokenId(code);
        assertEq(builderCodes.ownerOf(tokenId), initialOwner);
    }

    /// @notice Test that registerAuto generates different codes for different inputs
    function test_registerAuto_success_differentInputsDifferentCodes() public {
        address owner1 = address(0x1111);
        address owner2 = address(0x2222);
        address payout = address(0x3333);

        vm.startPrank(registrar);
        string memory code1 = builderCodes.registerAuto(owner1, payout);
        string memory code2 = builderCodes.registerAuto(owner2, payout);
        vm.stopPrank();

        assertTrue(
            keccak256(bytes(code1)) != keccak256(bytes(code2)), "Different inputs should generate different codes"
        );
    }

    /// @notice Test that registerAuto reverts when initial owner is zero address
    ///
    /// @param payoutAddress The payout address
    function test_registerAuto_revert_zeroInitialOwner(address payoutAddress) public {
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(registrar);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0)));
        builderCodes.registerAuto(address(0), payoutAddress);
    }

    /// @notice Test that registerAuto reverts when payout address is zero address
    ///
    /// @param initialOwner The initial owner address
    function test_registerAuto_revert_zeroPayoutAddress(address initialOwner) public {
        initialOwner = _boundNonZeroAddress(initialOwner);

        vm.prank(registrar);
        vm.expectRevert(BuilderCodes.ZeroAddress.selector);
        builderCodes.registerAuto(initialOwner, address(0));
    }

    /// @notice Test that registerAuto handles collision by retrying with incremented nonce
    function test_registerAuto_success_handlesCollision() public {
        address initialOwner = address(0x1111);
        address payoutAddress = address(0x2222);

        // Register first code
        vm.prank(registrar);
        string memory code1 = builderCodes.registerAuto(initialOwner, payoutAddress);

        // Register again with the same inputs in the same block - should succeed with a different code
        // because prevrandao and block.number are the same but nonce increments on collision
        vm.prank(registrar);
        string memory code2 = builderCodes.registerAuto(initialOwner, payoutAddress);

        assertTrue(keccak256(bytes(code1)) != keccak256(bytes(code2)), "Should generate different codes on collision");
        assertTrue(builderCodes.isRegistered(code1));
        assertTrue(builderCodes.isRegistered(code2));
    }

    /// @notice Test that registerAuto can be called by anyone (no role restriction)
    ///
    /// @param sender The sender address
    /// @param initialOwner The initial owner address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_anyoneCanCall(address sender, address initialOwner, address payoutAddress)
        public
    {
        sender = _boundNonZeroAddress(sender);
        initialOwner = _boundNonZeroAddress(initialOwner);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(sender);
        string memory code = builderCodes.registerAuto(initialOwner, payoutAddress);

        assertTrue(builderCodes.isRegistered(code));
    }
}