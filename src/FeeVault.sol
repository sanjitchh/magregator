// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/IERC20.sol";
import "./interface/IFeeVault.sol";
import "./lib/SafeERC20.sol";
import "./lib/Maintainable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract FeeVault is Initializable, UUPSUpgradeable, Maintainable, IFeeVault {
    using SafeERC20 for IERC20;

    uint256 public constant BPS_DENOMINATOR = 1e4;

    address public ROUTER;
    address public EXECUTOR;
    address public USDC;
    address public RECOVERY_RECIPIENT;
    uint256 public RECOVERY_CAP_USDC;
    uint256 public recoveryAccruedUsdc;
    address public DEVELOPMENT_RECIPIENT;
    uint256 public DEVELOPMENT_CAP_USDC;
    uint256 public developmentAccruedUsdc;
    address public POST_CAP_COMPANY_RECIPIENT;
    address public PROTOCOL_RECIPIENT;
    uint256 public POST_CAP_COMPANY_BPS;
    uint256 public pendingRecoveryUsdc;
    uint256 public pendingDevelopmentUsdc;
    uint256 public pendingPostCapCompanyUsdc;
    uint256 public pendingProtocolUsdc;

    mapping(address => bool) public ALLOWED_SWAP_TARGETS;

    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    function initialize(
        address _router,
        address _executor,
        address _usdc,
        address _initialMaintainer,
        address _recoveryRecipient,
        uint256 _recoveryCapUsdc,
        address _developmentRecipient,
        uint256 _developmentCapUsdc,
        address _postCapCompanyRecipient,
        address _protocolRecipient,
        uint256 _postCapCompanyBps
    ) external initializer {
        require(_usdc != address(0), "FeeVault: Invalid USDC");
        require(_postCapCompanyBps <= BPS_DENOMINATOR, "FeeVault: Invalid fee bps");

        __Maintainable_init(_initialMaintainer);

        ROUTER = _router;
        EXECUTOR = _executor;
        USDC = _usdc;
        RECOVERY_RECIPIENT = _recoveryRecipient;
        RECOVERY_CAP_USDC = _recoveryCapUsdc;
        DEVELOPMENT_RECIPIENT = _developmentRecipient;
        DEVELOPMENT_CAP_USDC = _developmentCapUsdc;
        POST_CAP_COMPANY_RECIPIENT = _postCapCompanyRecipient;
        PROTOCOL_RECIPIENT = _protocolRecipient;
        POST_CAP_COMPANY_BPS = _postCapCompanyBps;
    }

    function _authorizeUpgrade(address) internal override onlyMaintainer {}

    function setRouter(address _router) external override onlyMaintainer {
        emit UpdatedRouter(ROUTER, _router);
        ROUTER = _router;
    }

    function setExecutor(address _executor) external override onlyMaintainer {
        emit UpdatedExecutor(EXECUTOR, _executor);
        EXECUTOR = _executor;
    }

    function setUsdc(address _usdc) external override onlyMaintainer {
        require(_usdc != address(0), "FeeVault: Invalid USDC");
        _requireUsdcMigrationSettled();
        require(recoveryAccruedUsdc == 0 && developmentAccruedUsdc == 0, "FeeVault: Use migration for accrued state");

        _setUsdc(_usdc);
    }

    function migrateUsdcAccounting(
        address _usdc,
        uint256 _recoveryCapUsdc,
        uint256 _recoveryAccruedUsdc,
        uint256 _developmentCapUsdc,
        uint256 _developmentAccruedUsdc
    ) external override onlyMaintainer {
        require(_usdc != address(0), "FeeVault: Invalid USDC");
        require(_recoveryAccruedUsdc <= _recoveryCapUsdc, "FeeVault: Recovery accrued exceeds cap");
        require(_developmentAccruedUsdc <= _developmentCapUsdc, "FeeVault: Development accrued exceeds cap");

        _requireUsdcMigrationSettled();

        address oldUsdc = USDC;
        uint256 oldRecoveryCapUsdc = RECOVERY_CAP_USDC;
        uint256 oldDevelopmentCapUsdc = DEVELOPMENT_CAP_USDC;

        _setUsdc(_usdc);

        if (oldRecoveryCapUsdc != _recoveryCapUsdc) {
            emit UpdatedRecoveryCapUsdc(oldRecoveryCapUsdc, _recoveryCapUsdc);
        }
        if (oldDevelopmentCapUsdc != _developmentCapUsdc) {
            emit UpdatedDevelopmentCapUsdc(oldDevelopmentCapUsdc, _developmentCapUsdc);
        }

        RECOVERY_CAP_USDC = _recoveryCapUsdc;
        recoveryAccruedUsdc = _recoveryAccruedUsdc;
        DEVELOPMENT_CAP_USDC = _developmentCapUsdc;
        developmentAccruedUsdc = _developmentAccruedUsdc;

        emit UsdcMigrationConfigured(
            oldUsdc,
            _usdc,
            _recoveryCapUsdc,
            _recoveryAccruedUsdc,
            _developmentCapUsdc,
            _developmentAccruedUsdc
        );
    }

    function setRecoveryRecipient(address _recoveryRecipient) external override onlyMaintainer {
        emit UpdatedRecoveryRecipient(RECOVERY_RECIPIENT, _recoveryRecipient);
        RECOVERY_RECIPIENT = _recoveryRecipient;
    }

    function setRecoveryCapUsdc(uint256 _recoveryCapUsdc) external override onlyMaintainer {
        emit UpdatedRecoveryCapUsdc(RECOVERY_CAP_USDC, _recoveryCapUsdc);
        RECOVERY_CAP_USDC = _recoveryCapUsdc;
    }

    function setDevelopmentRecipient(address _developmentRecipient) external override onlyMaintainer {
        emit UpdatedDevelopmentRecipient(DEVELOPMENT_RECIPIENT, _developmentRecipient);
        DEVELOPMENT_RECIPIENT = _developmentRecipient;
    }

    function setDevelopmentCapUsdc(uint256 _developmentCapUsdc) external override onlyMaintainer {
        emit UpdatedDevelopmentCapUsdc(DEVELOPMENT_CAP_USDC, _developmentCapUsdc);
        DEVELOPMENT_CAP_USDC = _developmentCapUsdc;
    }

    function setPostCapCompanyRecipient(address _postCapCompanyRecipient) external override onlyMaintainer {
        emit UpdatedPostCapCompanyRecipient(POST_CAP_COMPANY_RECIPIENT, _postCapCompanyRecipient);
        POST_CAP_COMPANY_RECIPIENT = _postCapCompanyRecipient;
    }

    function setProtocolRecipient(address _protocolRecipient) external override onlyMaintainer {
        emit UpdatedProtocolRecipient(PROTOCOL_RECIPIENT, _protocolRecipient);
        PROTOCOL_RECIPIENT = _protocolRecipient;
    }

    function setPostCapCompanyBps(uint256 _postCapCompanyBps) external override onlyMaintainer {
        require(_postCapCompanyBps <= BPS_DENOMINATOR, "FeeVault: Invalid fee bps");
        emit UpdatedPostCapCompanyBps(POST_CAP_COMPANY_BPS, _postCapCompanyBps);
        POST_CAP_COMPANY_BPS = _postCapCompanyBps;
    }

    function setAllowedSwapTarget(address _target, bool _allowed) external override onlyMaintainer {
        emit UpdatedAllowedSwapTarget(_target, _allowed);
        ALLOWED_SWAP_TARGETS[_target] = _allowed;
    }

    function setTokenApproval(address _token, address _spender, uint256 _amount) external override {
        require(_isExecutorOrMaintainer(msg.sender), "FeeVault: Caller is not authorized");
        require(ALLOWED_SWAP_TARGETS[_spender], "FeeVault: Target not allowed");

        _forceApprove(_token, _spender, _amount);
        emit UpdatedTokenApproval(_token, _spender, _amount);
    }

    function executeAndDistribute(VaultCall[] calldata _calls, uint256 _minUsdcOut) external override returns (uint256) {
        require(_isExecutorOrMaintainer(msg.sender), "FeeVault: Caller is not authorized");

        uint256 pendingBefore = _pendingUsdcTotal();
        uint256 usdcBefore = IERC20(USDC).balanceOf(address(this));

        for (uint256 i = 0; i < _calls.length; i++) {
            VaultCall calldata callData = _calls[i];
            require(ALLOWED_SWAP_TARGETS[callData.target], "FeeVault: Target not allowed");

            (bool success, bytes memory returndata) = callData.target.call(callData.data);
            if (!success) {
                if (returndata.length > 0) {
                    assembly {
                        revert(add(returndata, 32), mload(returndata))
                    }
                }
                revert("FeeVault: Call failed");
            }
        }

        uint256 usdcAfter = IERC20(USDC).balanceOf(address(this));
        uint256 usdcRecovered = usdcAfter - usdcBefore;
        require(usdcRecovered >= _minUsdcOut, "FeeVault: Insufficient USDC output");
        require(usdcAfter >= pendingBefore, "FeeVault: Pending USDC exceeds balance");

        uint256 allocatableUsdc = usdcAfter - pendingBefore;
        if (allocatableUsdc > 0) {
            _allocateRecoveredUsdc(allocatableUsdc);
        }
        _distributePendingUsdcInternal();

        emit ConversionBatchExecuted(_calls.length, usdcRecovered);
        return usdcRecovered;
    }

    function distributePendingUsdc() external override onlyMaintainer {
        _distributePendingUsdcInternal();
    }

    function remainingRecoveryCapUsdc() public view override returns (uint256) {
        if (recoveryAccruedUsdc >= RECOVERY_CAP_USDC) {
            return 0;
        }

        return RECOVERY_CAP_USDC - recoveryAccruedUsdc;
    }

    function remainingDevelopmentCapUsdc() public view override returns (uint256) {
        if (developmentAccruedUsdc >= DEVELOPMENT_CAP_USDC) {
            return 0;
        }

        return DEVELOPMENT_CAP_USDC - developmentAccruedUsdc;
    }

    function _pendingUsdcTotal() internal view returns (uint256) {
        return pendingRecoveryUsdc + pendingDevelopmentUsdc + pendingPostCapCompanyUsdc + pendingProtocolUsdc;
    }

    function _allocateRecoveredUsdc(uint256 _usdcRecovered) internal {
        uint256 recoveryAmount;
        uint256 developmentAmount;
        uint256 postCapCompanyAmount;
        uint256 protocolAmount;
        uint256 remaining = _usdcRecovered;

        uint256 recoveryRemaining = remainingRecoveryCapUsdc();
        if (recoveryRemaining > 0) {
            recoveryAmount = remaining < recoveryRemaining ? remaining : recoveryRemaining;
            remaining -= recoveryAmount;
            recoveryAccruedUsdc += recoveryAmount;
            pendingRecoveryUsdc += recoveryAmount;
        }

        uint256 developmentRemaining = remainingDevelopmentCapUsdc();
        if (remaining > 0 && developmentRemaining > 0) {
            developmentAmount = remaining < developmentRemaining ? remaining : developmentRemaining;
            remaining -= developmentAmount;
            developmentAccruedUsdc += developmentAmount;
            pendingDevelopmentUsdc += developmentAmount;
        }

        if (remaining > 0) {
            postCapCompanyAmount = (remaining * POST_CAP_COMPANY_BPS) / BPS_DENOMINATOR;
            protocolAmount = remaining - postCapCompanyAmount;
            pendingPostCapCompanyUsdc += postCapCompanyAmount;
            pendingProtocolUsdc += protocolAmount;
        }

        emit UsdcAllocated(recoveryAmount, developmentAmount, postCapCompanyAmount, protocolAmount);
    }

    function _distributePendingUsdcInternal() internal {
        _distributeBucket(RECOVERY_RECIPIENT, pendingRecoveryUsdc, 0);
        _distributeBucket(DEVELOPMENT_RECIPIENT, pendingDevelopmentUsdc, 1);
        _distributeBucket(POST_CAP_COMPANY_RECIPIENT, pendingPostCapCompanyUsdc, 2);
        _distributeBucket(PROTOCOL_RECIPIENT, pendingProtocolUsdc, 3);
    }

    function _distributeBucket(address _recipient, uint256 _amount, uint256 _bucket) internal {
        if (_recipient == address(0) || _amount == 0) {
            return;
        }

        if (_bucket == 0) {
            pendingRecoveryUsdc = 0;
        } else if (_bucket == 1) {
            pendingDevelopmentUsdc = 0;
        } else if (_bucket == 2) {
            pendingPostCapCompanyUsdc = 0;
        } else {
            pendingProtocolUsdc = 0;
        }

        IERC20(USDC).safeTransfer(_recipient, _amount);

        if (_bucket == 0) {
            emit RecoveryUsdcDistributed(_recipient, _amount);
        } else if (_bucket == 1) {
            emit DevelopmentUsdcDistributed(_recipient, _amount);
        } else if (_bucket == 2) {
            emit PostCapCompanyUsdcDistributed(_recipient, _amount);
        } else {
            emit ProtocolUsdcDistributed(_recipient, _amount);
        }
    }

    function _forceApprove(address _token, address _spender, uint256 _amount) internal {
        IERC20 token = IERC20(_token);
        uint256 currentAllowance = token.allowance(address(this), _spender);

        if (currentAllowance > 0) {
            token.safeApprove(_spender, 0);
        }

        token.safeApprove(_spender, _amount);
    }

    function _setUsdc(address _usdc) internal {
        emit UpdatedUsdc(USDC, _usdc);
        USDC = _usdc;
    }

    function _requireUsdcMigrationSettled() internal view {
        require(_pendingUsdcTotal() == 0, "FeeVault: Pending USDC not settled");
        require(IERC20(USDC).balanceOf(address(this)) == 0, "FeeVault: Old USDC balance not settled");
    }

    function _isExecutorOrMaintainer(address _account) internal view returns (bool) {
        return _account == EXECUTOR || hasRole(MAINTAINER_ROLE, _account);
    }
}
