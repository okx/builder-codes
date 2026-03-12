// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {BuilderCodes} from "../src/BuilderCodes.sol";

/// @notice Script for granting a Builder Codes register role to an account
contract GrantRegisterRole is Script {
    function run() external {
        address proxy = vm.envAddress("BUILDER_CODES_PROXY");
        address account = vm.envAddress("GRANT_ACCOUNT");

        BuilderCodes builderCodes = BuilderCodes(proxy);

        console.log("BuilderCodes proxy:", proxy);
        console.log("Granting REGISTER_ROLE to:", account);

        vm.startBroadcast();

        bytes32 role = builderCodes.REGISTER_ROLE();
        builderCodes.grantRole(role, account);

        assert(builderCodes.hasRole(role, account));

        console.log("Granted REGISTER_ROLE to", account);

        vm.stopBroadcast();
    }
}
