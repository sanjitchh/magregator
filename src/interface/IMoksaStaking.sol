// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMoksaStaking {
    event Staked(address indexed account, uint256 amount);
    event UnstakeRequested(address indexed account, uint256 indexed requestId, uint256 amount, uint256 unlockTime);
    event UnbondedWithdrawal(address indexed account, uint256 indexed requestId, uint256 amount);
    event RewardPaid(address indexed account, uint256 amount);
    event RewardsDeposited(uint256 amount, uint256 rewardTreasuryBalance);
    event AnnualEmissionUpdated(uint256 oldAnnualEmission, uint256 newAnnualEmission);
    event UnbondingPeriodUpdated(uint256 oldUnbondingPeriod, uint256 newUnbondingPeriod);
    event ExcessTokenRecovered(address indexed token, address indexed recipient, uint256 amount);

    function stake(uint256 amount) external;
    function requestUnstake(uint256 amount) external;
    function withdrawUnbonded(uint256[] calldata requestIds) external;
    function claimReward() external;
    function depositRewards(uint256 amount) external;
    function setAnnualEmission(uint256 newAnnualEmission) external;
    function setUnbondingPeriod(uint256 newUnbondingPeriod) external;
    function recoverExcessERC20(address token, uint256 amount, address recipient) external;

    function earned(address account) external view returns (uint256);
    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function previewAnnualRewards(address account) external view returns (uint256);
    function currentApyBps() external view returns (uint256);
    function availableRewardFunding() external view returns (uint256);
    function unbondingRequestsCount(address account) external view returns (uint256);
    function getUnbondingRequest(address account, uint256 index)
        external
        view
        returns (uint256 amount, uint256 requestTime, uint256 unlockTime, bool withdrawn);
}
