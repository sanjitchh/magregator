// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IMoksaStaking.sol";
import "./interface/IERC20.sol";
import "./lib/SafeERC20.sol";
import "./lib/Maintainable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract MoksaStaking is Initializable, UUPSUpgradeable, Maintainable, IMoksaStaking {
    using SafeERC20 for IERC20;

    uint256 public constant REWARD_PRECISION = 1e18;

    struct UnbondingRequest {
        uint256 amount;
        uint256 requestTime;
        uint256 unlockTime;
        bool withdrawn;
    }

    address public STAKING_TOKEN;
    address public REWARD_TOKEN;
    uint256 public UNBONDING_PERIOD;

    uint256 public totalActiveSupply;
    uint256 public totalUnbondingSupply;
    uint256 public rewardRate; // Deprecated storage slot kept for upgrade safety.
    uint256 public periodFinish; // Deprecated storage slot kept for upgrade safety.
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public rewardBalanceOwed;
    uint256 public annualEmission;
    uint256 public rewardTreasuryBalance;

    mapping(address => uint256) public activeBalanceOf;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => UnbondingRequest[]) internal _unbondingRequests;

    constructor() {
        _disableInitializers();
    }

    function initialize(address stakingToken, address rewardToken, uint256 unbondingPeriod, address initialMaintainer)
        external
        initializer
    {
        require(stakingToken != address(0), "MoksaStaking: Invalid staking token");
        require(rewardToken != address(0), "MoksaStaking: Invalid reward token");

        __Maintainable_init(initialMaintainer);

        STAKING_TOKEN = stakingToken;
        REWARD_TOKEN = rewardToken;
        UNBONDING_PERIOD = unbondingPeriod;
    }

    function _authorizeUpgrade(address) internal override onlyMaintainer {}

    function stake(uint256 amount) external override {
        _updateReward(msg.sender);
        require(amount > 0, "MoksaStaking: Invalid amount");

        totalActiveSupply += amount;
        activeBalanceOf[msg.sender] += amount;
        IERC20(STAKING_TOKEN).safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    function requestUnstake(uint256 amount) external override {
        _updateReward(msg.sender);
        require(amount > 0, "MoksaStaking: Invalid amount");
        require(amount <= activeBalanceOf[msg.sender], "MoksaStaking: Insufficient active balance");

        activeBalanceOf[msg.sender] -= amount;
        totalActiveSupply -= amount;
        totalUnbondingSupply += amount;

        uint256 unlockTime = block.timestamp + UNBONDING_PERIOD;
        _unbondingRequests[msg.sender].push(
            UnbondingRequest({amount: amount, requestTime: block.timestamp, unlockTime: unlockTime, withdrawn: false})
        );

        emit UnstakeRequested(msg.sender, _unbondingRequests[msg.sender].length - 1, amount, unlockTime);
    }

    function withdrawUnbonded(uint256[] calldata requestIds) external override {
        uint256 totalToWithdraw;
        UnbondingRequest[] storage requests = _unbondingRequests[msg.sender];

        for (uint256 i = 0; i < requestIds.length; i++) {
            uint256 requestId = requestIds[i];
            require(requestId < requests.length, "MoksaStaking: Invalid request id");

            UnbondingRequest storage request = requests[requestId];
            require(!request.withdrawn, "MoksaStaking: Already withdrawn");
            require(block.timestamp >= request.unlockTime, "MoksaStaking: Unbonding not finished");

            request.withdrawn = true;
            totalToWithdraw += request.amount;

            emit UnbondedWithdrawal(msg.sender, requestId, request.amount);
        }

        require(totalToWithdraw > 0, "MoksaStaking: Nothing to withdraw");

        totalUnbondingSupply -= totalToWithdraw;
        IERC20(STAKING_TOKEN).safeTransfer(msg.sender, totalToWithdraw);
    }

    function claimReward() external override {
        _updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "MoksaStaking: No rewards");

        rewards[msg.sender] = 0;
        rewardBalanceOwed -= reward;
        rewardTreasuryBalance -= reward;
        IERC20(REWARD_TOKEN).safeTransfer(msg.sender, reward);

        emit RewardPaid(msg.sender, reward);
    }

    function depositRewards(uint256 amount) external override onlyMaintainer {
        _updateReward(address(0));
        require(amount > 0, "MoksaStaking: Invalid amount");

        uint256 fundedAmount = _pullRewardFunding(amount);
        require(fundedAmount > 0, "MoksaStaking: No rewards funded");

        rewardTreasuryBalance += fundedAmount;

        emit RewardsDeposited(fundedAmount, rewardTreasuryBalance);
    }

    function setAnnualEmission(uint256 newAnnualEmission) external override onlyMaintainer {
        _updateReward(address(0));
        require(_availableRewardFunding() >= newAnnualEmission, "MoksaStaking: Underfunded annual emission");

        emit AnnualEmissionUpdated(annualEmission, newAnnualEmission);
        annualEmission = newAnnualEmission;
    }

    function setUnbondingPeriod(uint256 newUnbondingPeriod) external override onlyMaintainer {
        emit UnbondingPeriodUpdated(UNBONDING_PERIOD, newUnbondingPeriod);
        UNBONDING_PERIOD = newUnbondingPeriod;
    }

    function recoverExcessERC20(address token, uint256 amount, address recipient) external override onlyMaintainer {
        require(recipient != address(0), "MoksaStaking: Invalid recipient");
        require(amount > 0, "MoksaStaking: Invalid amount");

        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 reserved = _reservedBalance(token);
        require(balance > reserved, "MoksaStaking: No excess balance");

        uint256 excess = balance - reserved;
        require(amount <= excess, "MoksaStaking: Amount exceeds excess");

        IERC20(token).safeTransfer(recipient, amount);
        emit ExcessTokenRecovered(token, recipient, amount);
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return block.timestamp;
    }

    function rewardPerToken() public view override returns (uint256) {
        return _rewardPerToken(lastTimeRewardApplicable());
    }

    function _rewardPerToken(uint256 applicableTime) internal view returns (uint256) {
        if (totalActiveSupply == 0) {
            return rewardPerTokenStored;
        }

        uint256 emittedRewards = _emittedRewardsSince(lastUpdateTime, applicableTime);
        return rewardPerTokenStored + ((emittedRewards * REWARD_PRECISION) / totalActiveSupply);
    }

    function earned(address account) public view override returns (uint256) {
        return _earned(account, _rewardPerToken(lastTimeRewardApplicable()));
    }

    function unbondingRequestsCount(address account) external view override returns (uint256) {
        return _unbondingRequests[account].length;
    }

    function previewAnnualRewards(address account) external view override returns (uint256) {
        if (totalActiveSupply == 0) {
            return 0;
        }

        return (activeBalanceOf[account] * annualEmission) / totalActiveSupply;
    }

    function currentApyBps() external view override returns (uint256) {
        if (totalActiveSupply == 0) {
            return 0;
        }

        return (annualEmission * 10_000) / totalActiveSupply;
    }

    function availableRewardFunding() external view override returns (uint256) {
        return _availableRewardFunding();
    }

    function getUnbondingRequest(address account, uint256 index)
        external
        view
        override
        returns (uint256 amount, uint256 requestTime, uint256 unlockTime, bool withdrawn)
    {
        require(index < _unbondingRequests[account].length, "MoksaStaking: Invalid request id");
        UnbondingRequest storage request = _unbondingRequests[account][index];
        return (request.amount, request.requestTime, request.unlockTime, request.withdrawn);
    }

    function _reservedBalance(address token) internal view returns (uint256) {
        uint256 reserved;

        if (token == STAKING_TOKEN) {
            reserved += totalActiveSupply + totalUnbondingSupply;
        }
        if (token == REWARD_TOKEN) {
            reserved += rewardTreasuryBalance;
        }

        return reserved;
    }

    function _earned(address account, uint256 currentRewardPerToken) internal view returns (uint256) {
        return ((activeBalanceOf[account] * (currentRewardPerToken - userRewardPerTokenPaid[account])) / REWARD_PRECISION)
            + rewards[account];
    }

    function _updateReward(address account) internal {
        uint256 applicableTime = lastTimeRewardApplicable();
        uint256 currentRewardPerToken = _rewardPerToken(applicableTime);
        uint256 emittedRewards = _emittedRewardsSince(lastUpdateTime, applicableTime);

        rewardPerTokenStored = currentRewardPerToken;
        lastUpdateTime = applicableTime;
        rewardBalanceOwed += emittedRewards;

        if (account != address(0)) {
            rewards[account] = _earned(account, currentRewardPerToken);
            userRewardPerTokenPaid[account] = currentRewardPerToken;
        }
    }

    function _pullRewardFunding(uint256 amount) internal returns (uint256 fundedAmount) {
        uint256 balanceBefore = IERC20(REWARD_TOKEN).balanceOf(address(this));
        IERC20(REWARD_TOKEN).safeTransferFrom(msg.sender, address(this), amount);
        fundedAmount = IERC20(REWARD_TOKEN).balanceOf(address(this)) - balanceBefore;
    }

    function _availableRewardFunding() internal view returns (uint256) {
        return rewardTreasuryBalance - rewardBalanceOwed;
    }

    function _emittedRewardsSince(uint256 fromTime, uint256 toTime) internal view returns (uint256) {
        if (toTime <= fromTime || annualEmission == 0) {
            return 0;
        }

        uint256 elapsed = toTime - fromTime;
        uint256 emittedRewards = (annualEmission * elapsed) / 365 days;
        uint256 availableFunding = _availableRewardFunding();

        if (emittedRewards > availableFunding) {
            return availableFunding;
        }

        return emittedRewards;
    }
}
