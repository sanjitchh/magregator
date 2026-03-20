// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DeploymentFactory} from "../../deployments/utils/DeploymentFactory.sol";
import {INetworkDeployments} from "../../deployments/utils/INetworkDeployments.sol";
import {FeeVault} from "../../src/FeeVault.sol";
import {IERC20} from "../../src/interface/IERC20.sol";

contract ManageFeeVault is Script {
    function runStatus() external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Router:", vault.ROUTER());
        console.log("Executor:", vault.EXECUTOR());
        console.log("USDC:", vault.USDC());
        console.log("Recovery recipient:", vault.RECOVERY_RECIPIENT());
        console.log("Recovery cap USDC:", vault.RECOVERY_CAP_USDC());
        console.log("Recovery accrued USDC:", vault.recoveryAccruedUsdc());
        console.log("Remaining recovery cap USDC:", vault.remainingRecoveryCapUsdc());
        console.log("Development recipient:", vault.DEVELOPMENT_RECIPIENT());
        console.log("Development cap USDC:", vault.DEVELOPMENT_CAP_USDC());
        console.log("Development accrued USDC:", vault.developmentAccruedUsdc());
        console.log("Remaining development cap USDC:", vault.remainingDevelopmentCapUsdc());
        console.log("Post-cap company recipient:", vault.POST_CAP_COMPANY_RECIPIENT());
        console.log("Protocol recipient:", vault.PROTOCOL_RECIPIENT());
        console.log("Post-cap company bps:", vault.POST_CAP_COMPANY_BPS());
        console.log("Pending recovery USDC:", vault.pendingRecoveryUsdc());
        console.log("Pending development USDC:", vault.pendingDevelopmentUsdc());
        console.log("Pending post-cap company USDC:", vault.pendingPostCapCompanyUsdc());
        console.log("Pending protocol USDC:", vault.pendingProtocolUsdc());
    }

    function runTokenBalance(address token) external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Token:", token);
        console.log("Vault token balance:", IERC20(token).balanceOf(address(vault)));
    }

    function runSetRouter(address routerAddress) external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Current router:", vault.ROUTER());
        console.log("New router:", routerAddress);

        vm.startBroadcast();
        vault.setRouter(routerAddress);
        vm.stopBroadcast();

        console.log("FeeVault router updated successfully");
    }

    function runSetExecutor(address executor) external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Current executor:", vault.EXECUTOR());
        console.log("New executor:", executor);

        vm.startBroadcast();
        vault.setExecutor(executor);
        vm.stopBroadcast();

        console.log("FeeVault executor updated successfully");
    }

    function runSetUsdc(address usdc) external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Current USDC:", vault.USDC());
        console.log("New USDC:", usdc);

        vm.startBroadcast();
        vault.setUsdc(usdc);
        vm.stopBroadcast();

        console.log("FeeVault USDC updated successfully");
    }

    function runSetRecoveryRecipient(address recoveryRecipient) external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Current recovery recipient:", vault.RECOVERY_RECIPIENT());
        console.log("New recovery recipient:", recoveryRecipient);

        vm.startBroadcast();
        vault.setRecoveryRecipient(recoveryRecipient);
        vm.stopBroadcast();

        console.log("FeeVault recovery recipient updated successfully");
    }

    function runSetRecoveryCapUsdc(uint256 recoveryCapUsdc) external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Current recovery cap USDC:", vault.RECOVERY_CAP_USDC());
        console.log("New recovery cap USDC:", recoveryCapUsdc);

        vm.startBroadcast();
        vault.setRecoveryCapUsdc(recoveryCapUsdc);
        vm.stopBroadcast();

        console.log("FeeVault recovery cap updated successfully");
    }

    function runSetDevelopmentRecipient(address developmentRecipient) external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Current development recipient:", vault.DEVELOPMENT_RECIPIENT());
        console.log("New development recipient:", developmentRecipient);

        vm.startBroadcast();
        vault.setDevelopmentRecipient(developmentRecipient);
        vm.stopBroadcast();

        console.log("FeeVault development recipient updated successfully");
    }

    function runSetDevelopmentCapUsdc(uint256 developmentCapUsdc) external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Current development cap USDC:", vault.DEVELOPMENT_CAP_USDC());
        console.log("New development cap USDC:", developmentCapUsdc);

        vm.startBroadcast();
        vault.setDevelopmentCapUsdc(developmentCapUsdc);
        vm.stopBroadcast();

        console.log("FeeVault development cap updated successfully");
    }

    function runSetPostCapCompanyRecipient(address postCapCompanyRecipient) external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Current post-cap company recipient:", vault.POST_CAP_COMPANY_RECIPIENT());
        console.log("New post-cap company recipient:", postCapCompanyRecipient);

        vm.startBroadcast();
        vault.setPostCapCompanyRecipient(postCapCompanyRecipient);
        vm.stopBroadcast();

        console.log("FeeVault post-cap company recipient updated successfully");
    }

    function runSetProtocolRecipient(address protocolRecipient) external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Current protocol recipient:", vault.PROTOCOL_RECIPIENT());
        console.log("New protocol recipient:", protocolRecipient);

        vm.startBroadcast();
        vault.setProtocolRecipient(protocolRecipient);
        vm.stopBroadcast();

        console.log("FeeVault protocol recipient updated successfully");
    }

    function runSetPostCapCompanyBps(uint256 postCapCompanyBps) external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Current post-cap company bps:", vault.POST_CAP_COMPANY_BPS());
        console.log("New post-cap company bps:", postCapCompanyBps);

        vm.startBroadcast();
        vault.setPostCapCompanyBps(postCapCompanyBps);
        vm.stopBroadcast();

        console.log("FeeVault post-cap company bps updated successfully");
    }

    function runSetAllowedSwapTarget(address target, bool allowed) external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Swap target:", target);
        console.log("Allowed:", allowed);

        vm.startBroadcast();
        vault.setAllowedSwapTarget(target, allowed);
        vm.stopBroadcast();

        console.log("FeeVault swap target updated successfully");
    }

    function runSetTokenApproval(address token, address spender, uint256 amount) external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));
        console.log("Token:", token);
        console.log("Spender:", spender);
        console.log("Amount:", amount);

        vm.startBroadcast();
        vault.setTokenApproval(token, spender, amount);
        vm.stopBroadcast();

        console.log("FeeVault token approval updated successfully");
    }

    function runDistributePendingUsdc() external {
        (INetworkDeployments deployments, FeeVault vault) = _vault();

        console.log("Network:", deployments.getNetworkName());
        console.log("FeeVault:", address(vault));

        vm.startBroadcast();
        vault.distributePendingUsdc();
        vm.stopBroadcast();

        console.log("FeeVault pending USDC distributed successfully");
    }

    function _vault() internal returns (INetworkDeployments deployments, FeeVault vault) {
        DeploymentFactory factory = new DeploymentFactory();
        deployments = factory.getDeployments();

        address feeVault = deployments.getFeeVault();
        require(feeVault != address(0), "ManageFeeVault: fee vault not configured");
        vault = FeeVault(payable(feeVault));
    }
}
