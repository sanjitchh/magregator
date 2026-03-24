// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct VaultCall {
    address target;
    bytes data;
}

interface IFeeVault {
    event UpdatedRouter(address _oldRouter, address _newRouter);
    event UpdatedExecutor(address _oldExecutor, address _newExecutor);
    event UpdatedUsdc(address _oldUsdc, address _newUsdc);
    event UsdcMigrationConfigured(
        address _oldUsdc,
        address _newUsdc,
        uint256 _recoveryCapUsdc,
        uint256 _recoveryAccruedUsdc,
        uint256 _developmentCapUsdc,
        uint256 _developmentAccruedUsdc
    );
    event UpdatedRecoveryRecipient(address _oldRecoveryRecipient, address _newRecoveryRecipient);
    event UpdatedRecoveryCapUsdc(uint256 _oldRecoveryCapUsdc, uint256 _newRecoveryCapUsdc);
    event UpdatedDevelopmentRecipient(address _oldDevelopmentRecipient, address _newDevelopmentRecipient);
    event UpdatedDevelopmentCapUsdc(uint256 _oldDevelopmentCapUsdc, uint256 _newDevelopmentCapUsdc);
    event UpdatedPostCapCompanyRecipient(address _oldPostCapCompanyRecipient, address _newPostCapCompanyRecipient);
    event UpdatedProtocolRecipient(address _oldProtocolRecipient, address _newProtocolRecipient);
    event UpdatedPostCapCompanyBps(uint256 _oldPostCapCompanyBps, uint256 _newPostCapCompanyBps);
    event UpdatedAllowedSwapTarget(address indexed _target, bool _allowed);
    event UpdatedTokenApproval(address indexed _token, address indexed _spender, uint256 _amount);
    event ConversionBatchExecuted(uint256 _callCount, uint256 _usdcRecovered);
    event UsdcAllocated(uint256 _recoveryAmount, uint256 _developmentAmount, uint256 _postCapCompanyAmount, uint256 _protocolAmount);
    event RecoveryUsdcDistributed(address indexed _to, uint256 _amount);
    event DevelopmentUsdcDistributed(address indexed _to, uint256 _amount);
    event PostCapCompanyUsdcDistributed(address indexed _to, uint256 _amount);
    event ProtocolUsdcDistributed(address indexed _to, uint256 _amount);

    function setRouter(address _router) external;
    function setExecutor(address _executor) external;
    function setUsdc(address _usdc) external;
    function migrateUsdcAccounting(
        address _usdc,
        uint256 _recoveryCapUsdc,
        uint256 _recoveryAccruedUsdc,
        uint256 _developmentCapUsdc,
        uint256 _developmentAccruedUsdc
    ) external;
    function setRecoveryRecipient(address _recoveryRecipient) external;
    function setRecoveryCapUsdc(uint256 _recoveryCapUsdc) external;
    function setDevelopmentRecipient(address _developmentRecipient) external;
    function setDevelopmentCapUsdc(uint256 _developmentCapUsdc) external;
    function setPostCapCompanyRecipient(address _postCapCompanyRecipient) external;
    function setProtocolRecipient(address _protocolRecipient) external;
    function setPostCapCompanyBps(uint256 _postCapCompanyBps) external;
    function setAllowedSwapTarget(address _target, bool _allowed) external;
    function setTokenApproval(address _token, address _spender, uint256 _amount) external;
    function executeAndDistribute(VaultCall[] calldata _calls, uint256 _minUsdcOut) external returns (uint256);
    function distributePendingUsdc() external;
    function remainingRecoveryCapUsdc() external view returns (uint256);
    function remainingDevelopmentCapUsdc() external view returns (uint256);
}
