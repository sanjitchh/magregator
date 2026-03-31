// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INetworkDeployments.sol";
import "../EthereumDeployments.sol";
import "../MonadDeployments.sol";
import "../SepoliaDeployments.sol";

contract DeploymentFactory {
    error UnsupportedNetwork(uint256 chainId);

    function getDeployments() public returns (INetworkDeployments) {
        uint256 chainId = block.chainid;

        if (chainId == 143 || chainId == 10143) {
            return INetworkDeployments(address(new MonadDeployments()));
        } else if (chainId == 1) {
            return INetworkDeployments(address(new EthereumDeployments()));
        } else if (chainId == 11155111) {
            return INetworkDeployments(address(new SepoliaDeployments()));
        } else {
            revert UnsupportedNetwork(chainId);
        }
    }

    function getDeploymentsByChainId(uint256 chainId) public returns (INetworkDeployments) {
        if (chainId == 143 || chainId == 10143) {
            return INetworkDeployments(address(new MonadDeployments()));
        } else if (chainId == 1) {
            return INetworkDeployments(address(new EthereumDeployments()));
        } else if (chainId == 11155111) {
            return INetworkDeployments(address(new SepoliaDeployments()));
        } else {
            revert UnsupportedNetwork(chainId);
        }
    }

    function getSupportedNetworks() public pure returns (uint256[] memory chainIds, string[] memory names) {
        chainIds = new uint256[](3);
        names = new string[](3);

        chainIds[0] = 143;
        names[0] = "Monad";

        chainIds[1] = 1;
        names[1] = "Ethereum Mainnet";

        chainIds[2] = 11155111;
        names[2] = "Ethereum Sepolia";
    }
}
