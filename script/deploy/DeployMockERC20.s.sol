// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

contract DeployMockERC20 is Script {
    function run(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        address owner,
        address initialRecipient,
        uint256 initialMint
    ) external {
        require(bytes(name).length > 0, "DeployMockERC20: empty name");
        require(bytes(symbol).length > 0, "DeployMockERC20: empty symbol");
        require(owner != address(0), "DeployMockERC20: invalid owner");

        vm.startBroadcast();

        MockERC20 token = new MockERC20(name, symbol, decimals, owner);
        if (initialMint > 0) {
            require(initialRecipient != address(0), "DeployMockERC20: invalid recipient");
            token.mint(initialRecipient, initialMint);
        }

        vm.stopBroadcast();

        console.log("MockERC20:", address(token));
        console.log("Name:", name);
        console.log("Symbol:", symbol);
        console.log("Decimals:", decimals);
        console.log("Owner:", owner);
        console.log("Initial recipient:", initialRecipient);
        console.log("Initial mint:", initialMint);
    }
}
