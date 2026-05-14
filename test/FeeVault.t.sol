// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {FeeVault} from "../src/FeeVault.sol";
import {VaultCall} from "../src/interface/IFeeVault.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract FeeVaultTest is Test {
    address internal constant ROUTER = address(0x1001);
    address internal constant EXECUTOR = address(0x1002);
    address internal constant RECOVERY = address(0x2001);
    address internal constant DEVELOPMENT = address(0x2002);
    address internal constant COMPANY = address(0x2003);
    address internal constant PROTOCOL = address(0x2004);

    MockERC20 internal oldUsdc;
    MockERC20 internal newUsdc;

    function setUp() public {
        oldUsdc = new MockERC20("Old USDC", "OUSDC");
        newUsdc = new MockERC20("New USDC", "NUSDC");
    }

    function testSetUsdcRevertsWhenPendingBalanceExists() public {
        FeeVault vault = _deployVault(address(0), DEVELOPMENT, 1_000_000, 1_000_000);

        oldUsdc.mint(address(vault), 100);
        vault.executeAndDistribute(new VaultCall[](0), 0);

        assertEq(vault.pendingRecoveryUsdc(), 100);

        vm.expectRevert("FeeVault: Pending USDC not settled");
        vault.setUsdc(address(newUsdc));
    }

    function testSetUsdcRevertsWhenAccruedStateExists() public {
        FeeVault vault = _deployVault(RECOVERY, DEVELOPMENT, 1_000_000, 1_000_000);

        oldUsdc.mint(address(vault), 100);
        vault.executeAndDistribute(new VaultCall[](0), 0);

        assertEq(vault.pendingRecoveryUsdc(), 0);
        assertEq(vault.recoveryAccruedUsdc(), 100);
        assertEq(oldUsdc.balanceOf(address(vault)), 0);

        vm.expectRevert("FeeVault: Use migration for accrued state");
        vault.setUsdc(address(newUsdc));
    }

    function testSetUsdcAllowsFreshVaultState() public {
        FeeVault vault = _deployVault(RECOVERY, DEVELOPMENT, 1_000_000, 1_000_000);

        vault.setUsdc(address(newUsdc));

        assertEq(vault.USDC(), address(newUsdc));
    }

    function testMigrateUsdcAccountingPreservesFlow() public {
        FeeVault vault = _deployVault(RECOVERY, DEVELOPMENT, 100, 100);

        oldUsdc.mint(address(vault), 60);
        vault.executeAndDistribute(new VaultCall[](0), 0);

        assertEq(vault.recoveryAccruedUsdc(), 60);
        assertEq(oldUsdc.balanceOf(RECOVERY), 60);

        vault.migrateUsdcAccounting(address(newUsdc), 200, 150, 300, 10);

        assertEq(vault.USDC(), address(newUsdc));
        assertEq(vault.RECOVERY_CAP_USDC(), 200);
        assertEq(vault.recoveryAccruedUsdc(), 150);
        assertEq(vault.DEVELOPMENT_CAP_USDC(), 300);
        assertEq(vault.developmentAccruedUsdc(), 10);

        newUsdc.mint(address(vault), 70);
        vault.executeAndDistribute(new VaultCall[](0), 0);

        assertEq(newUsdc.balanceOf(RECOVERY), 50);
        assertEq(newUsdc.balanceOf(DEVELOPMENT), 20);
        assertEq(vault.recoveryAccruedUsdc(), 200);
        assertEq(vault.developmentAccruedUsdc(), 30);
        assertEq(vault.pendingRecoveryUsdc(), 0);
        assertEq(vault.pendingDevelopmentUsdc(), 0);
    }

    function _deployVault(
        address recoveryRecipient,
        address developmentRecipient,
        uint256 recoveryCapUsdc,
        uint256 developmentCapUsdc
    ) internal returns (FeeVault vault) {
        FeeVault implementation = new FeeVault();
        bytes memory initData = abi.encodeCall(
            FeeVault.initialize,
            (
                ROUTER,
                EXECUTOR,
                address(oldUsdc),
                address(this),
                recoveryRecipient,
                recoveryCapUsdc,
                developmentRecipient,
                developmentCapUsdc,
                COMPANY,
                PROTOCOL,
                5_000
            )
        );
        vault = FeeVault(payable(address(new ERC1967Proxy(address(implementation), initData))));
    }
}
