// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MoksaStaking} from "../src/MoksaStaking.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MoksaStakingTest is Test {
    uint256 internal constant UNBONDING_PERIOD = 7 days;

    address internal constant MAINTAINER = address(0xA11CE);
    address internal constant ALICE = address(0xB0B);
    address internal constant BOB = address(0xCAFE);

    MockERC20 internal token;
    MoksaStaking internal staking;

    function setUp() external {
        token = new MockERC20("Stake", "STK");
        staking = _deployStaking(address(token), address(token));

        token.mint(ALICE, 1_000 ether);
        token.mint(BOB, 1_000 ether);
        token.mint(MAINTAINER, 10_000 ether);

        vm.prank(ALICE);
        token.approve(address(staking), type(uint256).max);

        vm.prank(BOB);
        token.approve(address(staking), type(uint256).max);

        vm.prank(MAINTAINER);
        token.approve(address(staking), type(uint256).max);
    }

    function testStakeAccruesByAnnualEmissionFormulaAndClaimsRewards() external {
        _depositRewards(365 ether);
        _setAnnualEmission(365 ether);

        vm.prank(ALICE);
        staking.stake(100 ether);

        vm.warp(block.timestamp + 30 days);

        assertApproxEqAbs(staking.previewAnnualRewards(ALICE), 365 ether, 1);
        assertApproxEqAbs(staking.currentApyBps(), 36_500, 1);

        uint256 earnedBeforeClaim = staking.earned(ALICE);
        assertApproxEqAbs(earnedBeforeClaim, 30 ether, 1e5);

        vm.prank(ALICE);
        staking.claimReward();

        assertApproxEqAbs(token.balanceOf(ALICE), 930 ether, 1e5);
        assertEq(staking.rewards(ALICE), 0);
    }

    function testMultipleStakersSplitAnnualEmissionProRata() external {
        _depositRewards(3_650 ether);
        _setAnnualEmission(3_650 ether);

        vm.prank(ALICE);
        staking.stake(100 ether);

        vm.prank(BOB);
        staking.stake(300 ether);

        vm.warp(block.timestamp + 4 days);

        assertApproxEqAbs(staking.previewAnnualRewards(ALICE), 1_825 ether / 2, 1);
        assertApproxEqAbs(staking.previewAnnualRewards(BOB), 5_475 ether / 2, 1);
        assertApproxEqAbs(staking.earned(ALICE), 10 ether, 1e5);
        assertApproxEqAbs(staking.earned(BOB), 30 ether, 1e5);
    }

    function testRequestUnstakeStopsRewardsAndWithdrawsAfterUnbonding() external {
        _depositRewards(365 ether);
        _setAnnualEmission(365 ether);

        vm.prank(ALICE);
        staking.stake(100 ether);

        vm.warp(block.timestamp + 20 days);

        vm.prank(ALICE);
        staking.requestUnstake(40 ether);

        uint256 rewardAtRequest = staking.earned(ALICE);
        assertApproxEqAbs(rewardAtRequest, 20 ether, 1e5);
        assertEq(staking.activeBalanceOf(ALICE), 60 ether);
        assertEq(staking.totalUnbondingSupply(), 40 ether);

        vm.warp(block.timestamp + 1 days);

        uint256 rewardAfterMoreTime = staking.earned(ALICE);
        assertApproxEqAbs(rewardAfterMoreTime - rewardAtRequest, 1 ether, 1e5);

        uint256[] memory requestIds = new uint256[](1);
        requestIds[0] = 0;

        vm.prank(ALICE);
        vm.expectRevert(bytes("MoksaStaking: Unbonding not finished"));
        staking.withdrawUnbonded(requestIds);

        vm.warp(block.timestamp + UNBONDING_PERIOD);

        uint256 balanceBefore = token.balanceOf(ALICE);

        vm.prank(ALICE);
        staking.withdrawUnbonded(requestIds);

        assertEq(token.balanceOf(ALICE), balanceBefore + 40 ether);
        assertEq(staking.totalUnbondingSupply(), 0);
    }

    function testAnnualEmissionCannotBeUnderfundedAndAccrualCapsAtTreasury() external {
        _depositRewards(10 ether);

        vm.prank(MAINTAINER);
        vm.expectRevert(bytes("MoksaStaking: Underfunded annual emission"));
        staking.setAnnualEmission(11 ether);

        _setAnnualEmission(10 ether);

        vm.prank(ALICE);
        staking.stake(100 ether);

        vm.warp(block.timestamp + 365 days);
        assertApproxEqAbs(staking.earned(ALICE), 10 ether, 1e5);

        vm.warp(block.timestamp + 365 days);
        assertApproxEqAbs(staking.earned(ALICE), 10 ether, 1e5);
    }

    function testRecoverExcessSameTokenOnlyRecoversAboveTrackedLiabilities() external {
        _depositRewards(100 ether);

        vm.prank(ALICE);
        staking.stake(50 ether);

        token.mint(address(staking), 25 ether);

        vm.prank(MAINTAINER);
        staking.recoverExcessERC20(address(token), 25 ether, MAINTAINER);

        assertEq(token.balanceOf(MAINTAINER), 9_925 ether);

        vm.prank(MAINTAINER);
        vm.expectRevert(bytes("MoksaStaking: No excess balance"));
        staking.recoverExcessERC20(address(token), 1 ether, MAINTAINER);
    }

    function _depositRewards(uint256 amount) internal {
        vm.prank(MAINTAINER);
        staking.depositRewards(amount);
    }

    function _setAnnualEmission(uint256 amount) internal {
        vm.prank(MAINTAINER);
        staking.setAnnualEmission(amount);
    }

    function _deployStaking(address stakingTokenAddress, address rewardTokenAddress) internal returns (MoksaStaking deployed) {
        MoksaStaking implementation = new MoksaStaking();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(MoksaStaking.initialize, (stakingTokenAddress, rewardTokenAddress, UNBONDING_PERIOD, MAINTAINER))
        );
        deployed = MoksaStaking(payable(address(proxy)));
    }
}
