// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {BuilderCodes} from "../../../src/BuilderCodes.sol";

// Create a mock V2 contract for testing upgrades
contract MockBuilderCodesV2 is BuilderCodes {
    function version() external pure returns (string memory) {
        return "2";
    }
}
