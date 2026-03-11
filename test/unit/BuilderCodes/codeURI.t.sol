// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {BuilderCodesTest, IERC721Errors} from "../../lib/BuilderCodesTest.sol";

import {BuilderCodes} from "../../../src/BuilderCodes.sol";

/// @notice Unit tests for BuilderCodes.codeURI
contract CodeURITest is BuilderCodesTest {
    /// @notice Test that codeURI reverts when code is not registered
    ///
    /// @param codeSeed The seed for generating the code
    function test_codeURI_revert_unregistered(uint256 codeSeed) public {
        string memory validCode = _generateValidCode(codeSeed);

        vm.expectRevert(
            abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, builderCodes.toTokenId(validCode))
        );
        builderCodes.codeURI(validCode);
    }

    /// @notice Test that codeURI reverts when code is empty
    function test_codeURI_revert_emptyCode() public {
        vm.expectRevert(abi.encodeWithSelector(BuilderCodes.InvalidCode.selector, ""));
        builderCodes.codeURI("");
    }

    /// @notice Test that codeURI reverts when code is over 32 characters
    ///
    /// @param codeSeed The seed for generating the code
    function test_codeURI_revert_codeOver32Characters(uint256 codeSeed) public {
        string memory longCode = _generateLongCode(codeSeed);

        vm.expectRevert(abi.encodeWithSelector(BuilderCodes.InvalidCode.selector, longCode));
        builderCodes.codeURI(longCode);
    }

    /// @notice Test that codeURI reverts when code contains invalid characters
    ///
    /// @param codeSeed The seed for generating the code
    function test_codeURI_revert_codeContainsInvalidCharacters(uint256 codeSeed) public {
        string memory invalidCode = _generateInvalidCode(codeSeed);

        vm.expectRevert(abi.encodeWithSelector(BuilderCodes.InvalidCode.selector, invalidCode));
        builderCodes.codeURI(invalidCode);
    }

    /// @notice Test that codeURI returns correct URI for registered code when base URI is set
    ///
    /// @param initialOwner The initial owner address
    /// @param initialPayoutAddress The initial payout address
    function test_codeURI_success_returnsCorrectURIWithBaseURI(
        address initialOwner,
        address initialPayoutAddress
    ) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        initialPayoutAddress = _boundNonZeroAddress(initialPayoutAddress);

        // Register a code first
        vm.prank(registrar);
        string memory validCode = builderCodes.register(initialOwner, initialPayoutAddress);

        string memory codeURI = builderCodes.codeURI(validCode);
        string memory expected = string.concat(URI_PREFIX, validCode);
        assertEq(codeURI, expected);
    }

    /// @notice Test that codeURI returns empty string when base URI is not set
    ///
    /// @param initialOwner The initial owner address
    /// @param initialPayoutAddress The initial payout address
    function test_codeURI_success_returnsEmptyStringWithoutBaseURI(
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

        string memory codeURI = freshContract.codeURI(validCode);
        assertEq(codeURI, "");
    }

    /// @notice Test that codeURI returns same result as tokenURI for equivalent inputs
    ///
    /// @param initialOwner The initial owner address
    /// @param initialPayoutAddress The initial payout address
    function test_codeURI_success_matchesTokenURI(address initialOwner, address initialPayoutAddress)
        public
    {
        initialOwner = _boundNonZeroAddress(initialOwner);
        initialPayoutAddress = _boundNonZeroAddress(initialPayoutAddress);

        // Register a code first
        vm.prank(registrar);
        string memory validCode = builderCodes.register(initialOwner, initialPayoutAddress);

        uint256 tokenId = builderCodes.toTokenId(validCode);
        string memory codeURI = builderCodes.codeURI(validCode);
        string memory tokenURI = builderCodes.tokenURI(tokenId);

        assertEq(codeURI, tokenURI);
    }

    /// @notice Test that codeURI reflects updated base URI
    ///
    /// @param initialOwner The initial owner address
    /// @param initialPayoutAddress The initial payout address
    /// @param newBaseURI The new base URI
    function test_codeURI_success_reflectsUpdatedBaseURI(
        address initialOwner,
        address initialPayoutAddress,
        string memory newBaseURI
    ) public {
        initialOwner = _boundNonZeroAddress(initialOwner);
        initialPayoutAddress = _boundNonZeroAddress(initialPayoutAddress);

        // Register a code first
        vm.prank(registrar);
        string memory validCode = builderCodes.register(initialOwner, initialPayoutAddress);

        // Update base URI
        vm.prank(owner);
        builderCodes.updateBaseURI(newBaseURI);

        string memory codeURI = builderCodes.codeURI(validCode);
        if (bytes(newBaseURI).length > 0) {
            string memory expected = string.concat(newBaseURI, validCode);
            assertEq(codeURI, expected);
        } else {
            assertEq(codeURI, "");
        }
    }
}
