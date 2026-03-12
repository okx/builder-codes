// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Vm} from "forge-std/Vm.sol";

import {BuilderCodes} from "../../../src/BuilderCodes.sol";

import {BuilderCodesTest, IERC721Errors} from "../../lib/BuilderCodesTest.sol";

/// @notice Unit tests for BuilderCodes.registerAuto
contract RegisterAutoTest is BuilderCodesTest {
    /// @notice Test that registerAuto successfully mints a token to msg.sender
    ///
    /// @param sender The sender address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_mintsToken(address sender, address payoutAddress) public {
        sender = _boundNonZeroAddress(sender);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(sender);
        string memory code = builderCodes.registerAuto(payoutAddress);

        uint256 tokenId = builderCodes.toTokenId(code);
        assertEq(builderCodes.ownerOf(tokenId), sender);
        assertTrue(builderCodes.isRegistered(code));
    }

    /// @notice Test that registerAuto generates a 16-character code
    ///
    /// @param sender The sender address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_generatesCorrectLength(address sender, address payoutAddress) public {
        sender = _boundNonZeroAddress(sender);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(sender);
        string memory code = builderCodes.registerAuto(payoutAddress);

        assertEq(bytes(code).length, builderCodes.GENERATED_CODE_LENGTH());
    }

    /// @notice Test that registerAuto generates a valid code
    ///
    /// @param sender The sender address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_generatesValidCode(address sender, address payoutAddress) public {
        sender = _boundNonZeroAddress(sender);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(sender);
        string memory code = builderCodes.registerAuto(payoutAddress);

        assertTrue(builderCodes.isValidCode(code));
    }

    /// @notice Test that registerAuto sets the payout address correctly
    ///
    /// @param sender The sender address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_setsPayoutAddress(address sender, address payoutAddress) public {
        sender = _boundNonZeroAddress(sender);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(sender);
        string memory code = builderCodes.registerAuto(payoutAddress);

        assertEq(builderCodes.payoutAddress(code), payoutAddress);
    }

    /// @notice Test that registerAuto emits CodeRegistered event
    ///
    /// @param sender The sender address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_emitsCodeRegistered(address sender, address payoutAddress) public {
        sender = _boundNonZeroAddress(sender);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.recordLogs();

        vm.prank(sender);
        string memory code = builderCodes.registerAuto(payoutAddress);

        uint256 tokenId = builderCodes.toTokenId(code);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool found = false;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == BuilderCodes.CodeRegistered.selector && logs[i].topics[1] == bytes32(tokenId)) {
                found = true;
                break;
            }
        }
        assertTrue(found, "CodeRegistered event not emitted");
    }

    /// @notice Test that registerAuto emits PayoutAddressUpdated event
    ///
    /// @param sender The sender address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_emitsPayoutAddressUpdated(address sender, address payoutAddress) public {
        sender = _boundNonZeroAddress(sender);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(sender);
        vm.expectEmit(false, false, false, true);
        emit BuilderCodes.PayoutAddressUpdated(0, payoutAddress);

        builderCodes.registerAuto(payoutAddress);
    }

    /// @notice Test that registerAuto generates different codes for different senders
    function test_registerAuto_success_differentSendersDifferentCodes() public {
        address sender1 = address(0x1111);
        address sender2 = address(0x2222);
        address payout = address(0x3333);

        vm.prank(sender1);
        string memory code1 = builderCodes.registerAuto(payout);
        vm.prank(sender2);
        string memory code2 = builderCodes.registerAuto(payout);

        assertTrue(
            keccak256(bytes(code1)) != keccak256(bytes(code2)), "Different senders should generate different codes"
        );
    }

    /// @notice Test that registerAuto reverts when payout address is zero address
    ///
    /// @param sender The sender address
    function test_registerAuto_revert_zeroPayoutAddress(address sender) public {
        sender = _boundNonZeroAddress(sender);

        vm.prank(sender);
        vm.expectRevert(BuilderCodes.ZeroAddress.selector);
        builderCodes.registerAuto(address(0));
    }

    /// @notice Test that registerAuto handles collision by retrying with incremented nonce
    function test_registerAuto_success_handlesCollision() public {
        address sender = address(0x1111);
        address payoutAddress = address(0x2222);

        // Register first code
        vm.prank(sender);
        string memory code1 = builderCodes.registerAuto(payoutAddress);

        // Register again with the same inputs in the same block - should succeed with a different code
        // because prevrandao and block.number are the same but nonce increments on collision
        vm.prank(sender);
        string memory code2 = builderCodes.registerAuto(payoutAddress);

        assertTrue(keccak256(bytes(code1)) != keccak256(bytes(code2)), "Should generate different codes on collision");
        assertTrue(builderCodes.isRegistered(code1));
        assertTrue(builderCodes.isRegistered(code2));
    }

    /// @notice Test that registerAuto can be called by anyone (no role restriction)
    ///
    /// @param sender The sender address
    /// @param payoutAddress The payout address
    function test_registerAuto_success_anyoneCanCall(address sender, address payoutAddress) public {
        sender = _boundNonZeroAddress(sender);
        payoutAddress = _boundNonZeroAddress(payoutAddress);

        vm.prank(sender);
        string memory code = builderCodes.registerAuto(payoutAddress);

        assertTrue(builderCodes.isRegistered(code));
    }

    /// @notice Test that registerAuto reverts with CodeGenerationFailed when all attempts collide
    function test_registerAuto_revert_codeGenerationFailed() public {
        address sender = address(0x1111);
        address payoutAddress = address(0x2222);

        // Pre-register all 50 codes that _generateCode would produce for these inputs
        bytes memory allowedChars = bytes(builderCodes.ALLOWED_CHARACTERS());
        uint8 codeLength = builderCodes.GENERATED_CODE_LENGTH();
        uint256 maxAttempts = builderCodes.MAX_CODE_GENERATION_ATTEMPTS();

        for (uint256 nonce = 0; nonce < maxAttempts; nonce++) {
            bytes32 hash =
                keccak256(abi.encodePacked(sender, payoutAddress, block.number, block.prevrandao, nonce));

            bytes memory result = new bytes(codeLength);
            for (uint256 i = 0; i < codeLength; i++) {
                result[i] = allowedChars[uint8(hash[i]) % allowedChars.length];
            }

            string memory code = string(result);
            vm.prank(registrar);
            builderCodes.register(code, address(0xdead), payoutAddress);
        }

        // Now registerAuto should exhaust all attempts and revert
        vm.prank(sender);
        vm.expectRevert(BuilderCodes.CodeGenerationFailed.selector);
        builderCodes.registerAuto(payoutAddress);
    }
}