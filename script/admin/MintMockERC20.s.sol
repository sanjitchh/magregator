// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

contract MintMockERC20 is Script {
    function run(address tokenAddress, address recipient, uint256 amount) external {
        require(tokenAddress != address(0), "MintMockERC20: invalid token");
        require(recipient != address(0), "MintMockERC20: invalid recipient");
        require(amount > 0, "MintMockERC20: invalid amount");

        MockERC20 token = MockERC20(tokenAddress);

        console.log("Token:", tokenAddress);
        console.log("Recipient:", recipient);
        console.log("Amount:", amount);

        vm.startBroadcast();
        token.mint(recipient, amount);
        vm.stopBroadcast();

        console.log("Minted mock tokens successfully");
    }
}
