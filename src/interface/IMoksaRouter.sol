// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


struct Query {
    address adapter;
    address tokenIn;
    address tokenOut;
    uint256 amountOut;
}
struct Offer {
    bytes amounts;
    bytes adapters;
    bytes path;
    uint256 gasEstimate;
}
struct FormattedOffer {
    uint256[] amounts;
    address[] adapters;
    address[] path;
    uint256 gasEstimate;
}
struct Trade {
    uint256 amountIn;
    uint256 amountOut;
    address[] path;
    address[] adapters;
}

interface IMoksaRouter {

    event UpdatedTrustedTokens(address[] _newTrustedTokens);
    event UpdatedAdapters(address[] _newAdapters);
    event UpdatedMinFee(uint256 _oldMinFee, uint256 _newMinFee);
    event UpdatedFeeClaimer(address _oldFeeClaimer, address _newFeeClaimer);
    event UpdatedHoldFees(bool _oldHoldFees, bool _newHoldFees);
    event UpdatedDeployerRedeemer(address _oldDeployerRedeemer, address _newDeployerRedeemer);
    event UpdatedSpecialRedeemEnabled(bool _oldSpecialRedeemEnabled, bool _newSpecialRedeemEnabled);
    event UpdatedSpecialRedeemCapUsd(uint256 _oldSpecialRedeemCapUsd, uint256 _newSpecialRedeemCapUsd);
    event UpdatedFeePriceFeed(address indexed _token, address _oldFeed, address _newFeed);
    event UpdatedPriceFeedStaleness(uint256 _oldPriceFeedStaleness, uint256 _newPriceFeedStaleness);
    event FeesClaimed(address indexed _token, address indexed _to, uint256 _amount);
    event SpecialFeesReserved(address indexed _token, uint256 _amount, uint256 _usdAmount);
    event SpecialFeesClaimed(address indexed _token, address indexed _to, uint256 _amount, uint256 _usdAmount);
    event MoksaSwap(address indexed _tokenIn, address indexed _tokenOut, uint256 _amountIn, uint256 _amountOut);

    // admin
    function setTrustedTokens(address[] memory _trustedTokens) external;
    function setAdapters(address[] memory _adapters) external;
    function setFeeClaimer(address _claimer) external;
    function setMinFee(uint256 _fee) external;
    function setHoldFees(bool _holdFees) external;
    function setDeployerRedeemer(address _deployerRedeemer) external;
    function setSpecialRedeemEnabled(bool _specialRedeemEnabled) external;
    function setSpecialRedeemCapUsd(uint256 _specialRedeemCapUsd) external;
    function setFeePriceFeed(address _token, address _priceFeed) external;
    function setPriceFeedStaleness(uint256 _priceFeedStaleness) external;
    function claimFees(address _token, address _to, uint256 _amount) external;
    function claimSpecialFees(address _token, uint256 _amount) external;
    function remainingSpecialRedeemUsd() external view returns (uint256);
    function getFeeUsdValue(address _token, uint256 _amount) external view returns (uint256);

    // misc
    function trustedTokensCount() external view returns (uint256);
    function adaptersCount() external view returns (uint256);

    // query

    function queryAdapter(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8 _index
    ) external returns (uint256);

    function queryNoSplit(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8[] calldata _options
    ) external view returns (Query memory);

    function queryNoSplit(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view returns (Query memory);

    function findBestPathWithGas(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps,
        uint256 _gasPrice
    ) external view returns (FormattedOffer memory);

    function findBestPath(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps
    ) external view returns (FormattedOffer memory);

    // swap

    function swapNoSplit(
        Trade calldata _trade,
        address _to,
        uint256 _fee
    ) external;

    function swapNoSplitFromNative(
        Trade calldata _trade,
        address _to,
        uint256 _fee
    ) external payable;

    function swapNoSplitToNative(
        Trade calldata _trade,
        address _to,
        uint256 _fee
    ) external; 

    function swapNoSplitWithPermit(
        Trade calldata _trade,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function swapNoSplitToNativeWithPermit(
        Trade calldata _trade,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

}
