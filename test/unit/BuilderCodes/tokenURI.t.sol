// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {BuilderCodes} from "../../../src/BuilderCodes.sol";
import {BuilderCodesTest, IERC721Errors} from "../../lib/BuilderCodesTest.sol";

/// @notice Unit tests for BuilderCodes.tokenURI
contract TokenURITest is BuilderCodesTest {
    /// @notice Test that tokenURI reverts when token ID does not exist
    ///
    /// @param tokenId The token ID
    function test_tokenURI_revert_tokenDoesNotExist(uint256 tokenId) public {
        // Ensure the token ID is not registered by trying a random high value
        tokenId = bound(tokenId, type(uint128).max, type(uint256).max);

        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, tokenId));
        builderCodes.tokenURI(tokenId);
    }

    /// @notice Test that tokenURI returns correct URI for registered token when base URI is set
    ///
    /// @param initialOwner The initial owner address
    /// @param initialPayoutAddress The initial payout address
    function test_tokenURI_success_returnsCorrectURIWithBaseURI(
        address initialOwner,
        address initialPayoutAddress
    ) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        initialPayoutAddress = _boundNonZeroAddress(initialPayoutAddress);

        // Register a code first
        vm.prank(registrar);
        string memory validCode = builderCodes.register(initialOwner, initialPayoutAddress);

        uint256 tokenId = builderCodes.toTokenId(validCode);
        string memory tokenURI = builderCodes.tokenURI(tokenId);

        // Should return base URI + code
        string memory expected = string.concat(URI_PREFIX, validCode);
        assertEq(tokenURI, expected);
    }

    /// @notice Test that tokenURI returns empty string when base URI is not set
    ///
    /// @param initialOwner The initial owner address
    /// @param initialPayoutAddress The initial payout address
    function test_tokenURI_success_returnsEmptyStringWithoutBaseURI(
        address initialOwner,
        address initialPayoutAddress
    ) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        initialPayoutAddress = _boundNonZeroAddress(initialPayoutAddress);

        // Deploy fresh contract with empty base URI
        BuilderCodes freshContract = _deployFreshBuilderCodes();
        freshContract.initialize(initialOwner, initialOwner, "");

        // Register a code
        vm.prank(initialOwner);
        string memory validCode = freshContract.register(initialOwner, initialPayoutAddress);

        uint256 tokenId = freshContract.toTokenId(validCode);
        string memory tokenURI = freshContract.tokenURI(tokenId);

        assertEq(tokenURI, "");
    }

    /// @notice Test that tokenURI returns same result as codeURI for equivalent inputs
    ///
    /// @param initialOwner The initial owner address
    /// @param initialPayoutAddress The initial payout address
    function test_tokenURI_success_matchesCodeURI(address initialOwner, address initialPayoutAddress)
        public
    {
        initialOwner = _boundNonZeroAddress(initialOwner);
        initialPayoutAddress = _boundNonZeroAddress(initialPayoutAddress);

        // Register a code first
        vm.prank(registrar);
        string memory validCode = builderCodes.register(initialOwner, initialPayoutAddress);

        uint256 tokenId = builderCodes.toTokenId(validCode);
        string memory tokenURI = builderCodes.tokenURI(tokenId);
        string memory codeURI = builderCodes.codeURI(validCode);

        assertEq(tokenURI, codeURI);
    }

    /// @notice Test that tokenURI reflects updated base URI
    ///
    /// @param initialOwner The initial owner address
    /// @param initialPayoutAddress The initial payout address
    /// @param newBaseURI The new base URI
    function test_tokenURI_success_reflectsUpdatedBaseURI(
        address initialOwner,
        address initialPayoutAddress,
        string memory newBaseURI
    ) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        initialPayoutAddress = _boundNonZeroAddress(initialPayoutAddress);

        // Register a code first
        vm.prank(registrar);
        string memory validCode = builderCodes.register(initialOwner, initialPayoutAddress);

        uint256 tokenId = builderCodes.toTokenId(validCode);

        // Update base URI
        vm.prank(owner);
        builderCodes.updateBaseURI(newBaseURI);

        string memory tokenURI = builderCodes.tokenURI(tokenId);
        if (bytes(newBaseURI).length > 0) {
            string memory expected = string.concat(newBaseURI, validCode);
            assertEq(tokenURI, expected);
        } else {
            assertEq(tokenURI, "");
        }
    }
}
