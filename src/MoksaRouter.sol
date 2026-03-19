// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./interface/IMoksaRouter.sol";
import "./interface/IAdapter.sol";
import "./interface/IERC20.sol";
import "./interface/IAggregatorV3.sol";
import "./interface/IWETH.sol";
import "./lib/SafeERC20.sol";
import "./lib/Maintainable.sol";
import "./lib/MoksaViewUtils.sol";
import "./lib/Recoverable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";


contract MoksaRouter is Initializable, UUPSUpgradeable, Maintainable, Recoverable, IMoksaRouter {
    using SafeERC20 for IERC20;
    using OfferUtils for Offer;

    address public WNATIVE;
    address public constant NATIVE = address(0);
    string public constant NAME = "MoksaRouter";
    uint256 public constant FEE_DENOMINATOR = 1e4;
    uint256 public MIN_FEE = 0;
    address public FEE_CLAIMER;
    address[] public TRUSTED_TOKENS;
    address[] public ADAPTERS;
    bool public HOLD_FEES;
    address public DEPLOYER_REDEEMER;
    bool public SPECIAL_REDEEM_ENABLED;
    uint256 public SPECIAL_REDEEM_CAP_USD;
    uint256 public specialAccruedUsd;
    uint256 public specialRedeemedUsd;
    uint256 public PRICE_FEED_STALENESS = 1 days;
    mapping(address => address) public FEE_PRICE_FEEDS;
    mapping(address => uint256) public SPECIAL_RESERVED_FEES;
    mapping(address => uint256) public SPECIAL_RESERVED_USD;
    address public COMPANY_FEE_CLAIMER;
    address public OPERATIONS_FEE_CLAIMER;
    uint256 public OPERATIONS_FEE_BPS;
    bool public COMPANY_PRE_CAP_ENABLED = true;
    uint256 public COMPANY_POST_CAP_FEE_BPS;
    uint256 public COMPANY_FEE_CAP_USD;
    uint256 public companyAccruedUsd;
    mapping(address => uint256) public OPERATIONS_RESERVED_FEES;
    mapping(address => uint256) public COMPANY_RESERVED_FEES;
    mapping(address => uint256) public PROTOCOL_RESERVED_FEES;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address[] memory _adapters,
        address[] memory _trustedTokens,
        address _feeClaimer,
        address _wrapped_native,
        address _initialMaintainer
    ) external initializer {
        __Maintainable_init(_initialMaintainer);

        setAllowanceForWrapping(_wrapped_native);
        setTrustedTokens(_trustedTokens);
        setFeeClaimer(_feeClaimer);
        setAdapters(_adapters);
        WNATIVE = _wrapped_native;
    }

    function _authorizeUpgrade(address) internal override onlyMaintainer {}

    // -- SETTERS --

    function setAllowanceForWrapping(address _wnative) public onlyMaintainer {
        IERC20(_wnative).safeApprove(_wnative, type(uint256).max);
    }

    function setTrustedTokens(address[] memory _trustedTokens) override public onlyMaintainer {
        emit UpdatedTrustedTokens(_trustedTokens);
        TRUSTED_TOKENS = _trustedTokens;
    }

    function setAdapters(address[] memory _adapters) override public onlyMaintainer {
        emit UpdatedAdapters(_adapters);
        ADAPTERS = _adapters;
    }

    function setMinFee(uint256 _fee) override external onlyMaintainer {
        emit UpdatedMinFee(MIN_FEE, _fee);
        MIN_FEE = _fee;
    }

    function setFeeClaimer(address _claimer) override public onlyMaintainer {
        emit UpdatedFeeClaimer(FEE_CLAIMER, _claimer);
        FEE_CLAIMER = _claimer;
    }

    function setCompanyFeeClaimer(address _companyFeeClaimer) override external onlyMaintainer {
        emit UpdatedCompanyFeeClaimer(COMPANY_FEE_CLAIMER, _companyFeeClaimer);
        COMPANY_FEE_CLAIMER = _companyFeeClaimer;
    }

    function setOperationsFeeClaimer(address _operationsFeeClaimer) override external onlyMaintainer {
        emit UpdatedOperationsFeeClaimer(OPERATIONS_FEE_CLAIMER, _operationsFeeClaimer);
        OPERATIONS_FEE_CLAIMER = _operationsFeeClaimer;
    }

    function setOperationsFeeBps(uint256 _operationsFeeBps) override external onlyMaintainer {
        require(_operationsFeeBps <= FEE_DENOMINATOR, "MoksaRouter: Invalid fee bps");
        emit UpdatedOperationsFeeBps(OPERATIONS_FEE_BPS, _operationsFeeBps);
        OPERATIONS_FEE_BPS = _operationsFeeBps;
    }

    function setCompanyPreCapEnabled(bool _companyPreCapEnabled) override external onlyMaintainer {
        emit UpdatedCompanyPreCapEnabled(COMPANY_PRE_CAP_ENABLED, _companyPreCapEnabled);
        COMPANY_PRE_CAP_ENABLED = _companyPreCapEnabled;
    }

    function setCompanyPostCapFeeBps(uint256 _companyPostCapFeeBps) override external onlyMaintainer {
        require(_companyPostCapFeeBps <= FEE_DENOMINATOR, "MoksaRouter: Invalid fee bps");
        emit UpdatedCompanyPostCapFeeBps(COMPANY_POST_CAP_FEE_BPS, _companyPostCapFeeBps);
        COMPANY_POST_CAP_FEE_BPS = _companyPostCapFeeBps;
    }

    function setCompanyFeeCapUsd(uint256 _companyFeeCapUsd) override external onlyMaintainer {
        emit UpdatedCompanyFeeCapUsd(COMPANY_FEE_CAP_USD, _companyFeeCapUsd);
        COMPANY_FEE_CAP_USD = _companyFeeCapUsd;
    }

    function setFeePriceFeed(address _token, address _priceFeed) override external onlyMaintainer {
        emit UpdatedFeePriceFeed(_token, FEE_PRICE_FEEDS[_token], _priceFeed);
        FEE_PRICE_FEEDS[_token] = _priceFeed;
    }

    function setPriceFeedStaleness(uint256 _priceFeedStaleness) override external onlyMaintainer {
        require(_priceFeedStaleness > 0, "MoksaRouter: Invalid staleness");
        emit UpdatedPriceFeedStaleness(PRICE_FEED_STALENESS, _priceFeedStaleness);
        PRICE_FEED_STALENESS = _priceFeedStaleness;
    }

    function claimOperationsFees(address _token, uint256 _amount) override external onlyMaintainer {
        require(_amount > 0, "MoksaRouter: Nothing to claim");
        require(OPERATIONS_FEE_CLAIMER != address(0), "MoksaRouter: Missing operations claimer");
        require(_amount <= OPERATIONS_RESERVED_FEES[_token], "MoksaRouter: Exceeds operations fees");

        OPERATIONS_RESERVED_FEES[_token] -= _amount;
        _transferTokenOut(_token, OPERATIONS_FEE_CLAIMER, _amount);

        emit OperationsFeesClaimed(_token, OPERATIONS_FEE_CLAIMER, _amount);
    }

    function claimCompanyFees(address _token, uint256 _amount) override external onlyMaintainer {
        require(_amount > 0, "MoksaRouter: Nothing to claim");
        require(COMPANY_FEE_CLAIMER != address(0), "MoksaRouter: Missing company claimer");
        require(_amount <= COMPANY_RESERVED_FEES[_token], "MoksaRouter: Exceeds company fees");

        COMPANY_RESERVED_FEES[_token] -= _amount;
        _transferTokenOut(_token, COMPANY_FEE_CLAIMER, _amount);

        emit CompanyFeesClaimed(_token, COMPANY_FEE_CLAIMER, _amount);
    }

    function claimProtocolFees(address _token, uint256 _amount) override external onlyMaintainer {
        require(_amount > 0, "MoksaRouter: Nothing to claim");
        require(FEE_CLAIMER != address(0), "MoksaRouter: Missing fee claimer");
        require(_amount <= PROTOCOL_RESERVED_FEES[_token], "MoksaRouter: Exceeds protocol fees");

        PROTOCOL_RESERVED_FEES[_token] -= _amount;
        _transferTokenOut(_token, FEE_CLAIMER, _amount);

        emit ProtocolFeesClaimed(_token, FEE_CLAIMER, _amount);
    }

    function remainingCompanyFeeCapUsd() override external view returns (uint256) {
        if (companyAccruedUsd >= COMPANY_FEE_CAP_USD) {
            return 0;
        }

        return COMPANY_FEE_CAP_USD - companyAccruedUsd;
    }

    function getFeeUsdValue(address _token, uint256 _amount) override external view returns (uint256) {
        (bool success, uint256 usdValue) = _tryGetFeeUsdValue(_token, _amount);
        require(success, "MoksaRouter: Missing price feed");
        return usdValue;
    }

    //  -- GENERAL --

    function trustedTokensCount() override external view returns (uint256) {
        return TRUSTED_TOKENS.length;
    }

    function adaptersCount() override external view returns (uint256) {
        return ADAPTERS.length;
    }

    function getTrustedTokens() external view returns (address[] memory) {
        return TRUSTED_TOKENS;
    }

    function getAdapters() external view returns (address[] memory) {
        return ADAPTERS;
    }

    // Fallback
    receive() external payable {}

    // -- HELPERS --

    function _applyFee(uint256 _amountIn, uint256 _fee) internal view returns (uint256) {
        require(_fee >= MIN_FEE, "MoksaRouter: Insufficient fee");
        return (_amountIn * (FEE_DENOMINATOR - _fee)) / FEE_DENOMINATOR;
    }

    function _wrap(uint256 _amount) internal {
        IWETH(WNATIVE).deposit{ value: _amount }();
    }

    function _unwrap(uint256 _amount) internal {
        IWETH(WNATIVE).withdraw(_amount);
    }

    /**
     * @notice Return tokens to user
     * @dev Pass address(0) for native token
     * @param _token address
     * @param _amount tokens to return
     * @param _to address where funds should be sent to
     */
    function _returnTokensTo(
        address _token,
        uint256 _amount,
        address _to
    ) internal {
        if (address(this) != _to) {
            if (_token == NATIVE) {
                payable(_to).transfer(_amount);
            } else {
                IERC20(_token).safeTransfer(_to, _amount);
            }
        }
    }

    function _transferFrom(address token, address _from, address _to, uint _amount) internal {
        if (_from != address(this))
            IERC20(token).safeTransferFrom(_from, _to, _amount);
        else
            IERC20(token).safeTransfer(_to, _amount);
    }

    function _transferTokenOut(address _token, address _to, uint256 _amount) internal {
        if (_token == NATIVE) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    function _collectFee(address _token, address _from, uint256 _feeAmount) internal {
        if (_feeAmount == 0) {
            return;
        }

        _transferFrom(_token, _from, address(this), _feeAmount);

        uint256 operationsAmount = (_feeAmount * OPERATIONS_FEE_BPS) / FEE_DENOMINATOR;
        uint256 remainingAmount = _feeAmount - operationsAmount;

        if (operationsAmount > 0) {
            _collectOperationsFee(_token, operationsAmount);
        }

        if (remainingAmount == 0) {
            return;
        }

        _reserveCompanyAndProtocolFees(_token, remainingAmount);
    }

    function _collectOperationsFee(address _token, uint256 _amount) internal {
        if (OPERATIONS_FEE_CLAIMER == address(0)) {
            OPERATIONS_RESERVED_FEES[_token] += _amount;
            emit OperationsFeesReserved(_token, _amount);
            return;
        }

        _transferTokenOut(_token, OPERATIONS_FEE_CLAIMER, _amount);
        emit OperationsFeesClaimed(_token, OPERATIONS_FEE_CLAIMER, _amount);
    }

    function _reserveCompanyAndProtocolFees(address _token, uint256 _feeAmount) internal {
        if (!COMPANY_PRE_CAP_ENABLED || COMPANY_FEE_CAP_USD == 0 || companyAccruedUsd >= COMPANY_FEE_CAP_USD) {
            _reservePostCapFees(_token, _feeAmount);
            return;
        }

        (bool success, uint256 feeUsdValue) = _tryGetFeeUsdValue(_token, _feeAmount);

        if (!success || feeUsdValue == 0) {
            _reservePostCapFees(_token, _feeAmount);
            return;
        }

        uint256 remainingUsd = COMPANY_FEE_CAP_USD - companyAccruedUsd;
        if (feeUsdValue <= remainingUsd) {
            _reserveCompanyFees(_token, _feeAmount, feeUsdValue);
            companyAccruedUsd += feeUsdValue;
            return;
        }

        (bool amountSuccess, uint256 companyPreCapAmount) = _tryGetTokenAmountForUsd(_token, remainingUsd);

        if (!amountSuccess || companyPreCapAmount == 0) {
            _reservePostCapFees(_token, _feeAmount);
            return;
        }

        if (companyPreCapAmount > _feeAmount) {
            companyPreCapAmount = _feeAmount;
        }

        uint256 companyPreCapUsd = _amountToUsdValue(_token, companyPreCapAmount);
        uint256 remainder = _feeAmount - companyPreCapAmount;

        if (companyPreCapAmount > 0) {
            _reserveCompanyFees(_token, companyPreCapAmount, companyPreCapUsd);
            companyAccruedUsd += companyPreCapUsd;
        }

        if (remainder > 0) {
            _reservePostCapFees(_token, remainder);
        }

        if (companyAccruedUsd >= COMPANY_FEE_CAP_USD || COMPANY_FEE_CAP_USD - companyAccruedUsd <= 1) {
            companyAccruedUsd = COMPANY_FEE_CAP_USD;
        }
    }

    function _reservePostCapFees(address _token, uint256 _feeAmount) internal {
        uint256 companyAmount = (_feeAmount * COMPANY_POST_CAP_FEE_BPS) / FEE_DENOMINATOR;
        uint256 protocolAmount = _feeAmount - companyAmount;

        if (companyAmount > 0) {
            _collectCompanyFee(_token, companyAmount);
        }

        if (protocolAmount > 0) {
            _collectProtocolFee(_token, protocolAmount);
        }
    }

    function _reserveCompanyFees(address _token, uint256 _amount, uint256 _usdAmount) internal {
        COMPANY_RESERVED_FEES[_token] += _amount;
        emit CompanyFeesReserved(_token, _amount, _usdAmount);
    }

    function _collectCompanyFee(address _token, uint256 _amount) internal {
        if (COMPANY_FEE_CLAIMER == address(0)) {
            _reserveCompanyFees(_token, _amount, 0);
            return;
        }

        _transferTokenOut(_token, COMPANY_FEE_CLAIMER, _amount);
        emit CompanyFeesClaimed(_token, COMPANY_FEE_CLAIMER, _amount);
    }

    function _collectProtocolFee(address _token, uint256 _amount) internal {
        if (FEE_CLAIMER == address(0)) {
            PROTOCOL_RESERVED_FEES[_token] += _amount;
            emit ProtocolFeesReserved(_token, _amount);
            return;
        }

        _transferTokenOut(_token, FEE_CLAIMER, _amount);
        emit ProtocolFeesClaimed(_token, FEE_CLAIMER, _amount);
    }

    function _amountToUsdValue(address _token, uint256 _amount) internal view returns (uint256) {
        (, uint256 usdValue) = _tryGetFeeUsdValue(_token, _amount);
        return usdValue;
    }

    function _tryGetFeeUsdValue(address _token, uint256 _amount) internal view returns (bool, uint256) {
        if (_amount == 0) {
            return (true, 0);
        }

        address priceFeed = FEE_PRICE_FEEDS[_token];
        if (priceFeed == address(0)) {
            return (false, 0);
        }

        try IAggregatorV3(priceFeed).latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            if (answer <= 0 || answeredInRound < roundId || updatedAt == 0 || block.timestamp - updatedAt > PRICE_FEED_STALENESS) {
                return (false, 0);
            }

            try IAggregatorV3(priceFeed).decimals() returns (uint8 feedDecimals) {
                uint256 scaledPrice = _scaleValue(uint256(answer), feedDecimals, 8);
                uint8 tokenDecimals = IERC20(_token).decimals();
                return (true, (_amount * scaledPrice) / (10 ** tokenDecimals));
            } catch {
                return (false, 0);
            }
        } catch {
            return (false, 0);
        }
    }

    function _tryGetTokenAmountForUsd(address _token, uint256 _usdAmount) internal view returns (bool, uint256) {
        address priceFeed = FEE_PRICE_FEEDS[_token];
        if (priceFeed == address(0)) {
            return (false, 0);
        }

        try IAggregatorV3(priceFeed).latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            if (answer <= 0 || answeredInRound < roundId || updatedAt == 0 || block.timestamp - updatedAt > PRICE_FEED_STALENESS) {
                return (false, 0);
            }

            try IAggregatorV3(priceFeed).decimals() returns (uint8 feedDecimals) {
                uint256 scaledPrice = _scaleValue(uint256(answer), feedDecimals, 8);
                uint8 tokenDecimals = IERC20(_token).decimals();
                return (true, (_usdAmount * (10 ** tokenDecimals)) / scaledPrice);
            } catch {
                return (false, 0);
            }
        } catch {
            return (false, 0);
        }
    }

    function _scaleValue(uint256 _value, uint8 _fromDecimals, uint8 _toDecimals) internal pure returns (uint256) {
        if (_fromDecimals == _toDecimals) {
            return _value;
        }

        if (_fromDecimals < _toDecimals) {
            return _value * (10 ** (_toDecimals - _fromDecimals));
        }

        return _value / (10 ** (_fromDecimals - _toDecimals));
    }
    
    // -- QUERIES --

    /**
     * Query single adapter
     */
    function queryAdapter(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8 _index
    ) override external view returns (uint256) {
        IAdapter _adapter = IAdapter(ADAPTERS[_index]);
        uint256 amountOut = _adapter.query(_amountIn, _tokenIn, _tokenOut);
        return amountOut;
    }

    /**
     * Query specified adapters
     */
    function queryNoSplit(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8[] calldata _options
    ) override public view returns (Query memory) {
        Query memory bestQuery;
        for (uint8 i; i < _options.length; i++) {
            address _adapter = ADAPTERS[_options[i]];
            uint256 amountOut = IAdapter(_adapter).query(_amountIn, _tokenIn, _tokenOut);
            if (i == 0 || amountOut > bestQuery.amountOut) {
                bestQuery = Query(_adapter, _tokenIn, _tokenOut, amountOut);
            }
        }
        return bestQuery;
    }

    /**
     * Query all adapters
     */
    function queryNoSplit(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) override public view returns (Query memory) {
        Query memory bestQuery;
        for (uint8 i; i < ADAPTERS.length; i++) {
            address _adapter = ADAPTERS[i];
            uint256 amountOut = IAdapter(_adapter).query(_amountIn, _tokenIn, _tokenOut);
            if (i == 0 || amountOut > bestQuery.amountOut) {
                bestQuery = Query(_adapter, _tokenIn, _tokenOut, amountOut);
            }
        }
        return bestQuery;
    }

    /**
     * Return path with best returns between two tokens
     * Takes gas-cost into account
     */
    function findBestPathWithGas(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps,
        uint256 _gasPrice
    ) override external view returns (FormattedOffer memory) {
        require(_maxSteps > 0 && _maxSteps < 5, "MoksaRouter: Invalid max-steps");
        Offer memory queries = OfferUtils.newOffer(_amountIn, _tokenIn);
        uint256 gasPriceInExitTkn = _gasPrice > 0 ? getGasPriceInExitTkn(_gasPrice, _tokenOut) : 0;
        queries = _findBestPath(_amountIn, _tokenIn, _tokenOut, _maxSteps, queries, gasPriceInExitTkn);
        if (queries.adapters.length == 0) {
            queries.amounts = "";
            queries.path = "";
        }
        return queries.format();
    }

    // Find the market price between gas-asset(native) and token-out and express gas price in token-out
    function getGasPriceInExitTkn(uint256 _gasPrice, address _tokenOut) internal view returns (uint256 price) {
        // Avoid low-liquidity price appreciation (https://github.com/moksa-labs/moksa-aggregator/issues/20)
        FormattedOffer memory gasQuery = findBestPath(1e18, WNATIVE, _tokenOut, 2);
        if (gasQuery.path.length != 0) {
            // Leave result in nWei to preserve precision for assets with low decimal places
            price = (gasQuery.amounts[gasQuery.amounts.length - 1] * _gasPrice) / 1e9;
        }
    }

    /**
     * Return path with best returns between two tokens
     */
    function findBestPath(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps
    ) override public view returns (FormattedOffer memory) {
        require(_maxSteps > 0 && _maxSteps < 5, "MoksaRouter: Invalid max-steps");
        Offer memory queries = OfferUtils.newOffer(_amountIn, _tokenIn);
        queries = _findBestPath(_amountIn, _tokenIn, _tokenOut, _maxSteps, queries, 0);
        // If no paths are found return empty struct
        if (queries.adapters.length == 0) {
            queries.amounts = "";
            queries.path = "";
        }
        return queries.format();
    }

    function _findBestPath(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps,
        Offer memory _queries,
        uint256 _tknOutPriceNwei
    ) internal view returns (Offer memory) {
        Offer memory bestOption = _queries.clone();
        uint256 bestAmountOut;
        uint256 gasEstimate;
        bool withGas = _tknOutPriceNwei != 0;

        // First check if there is a path directly from tokenIn to tokenOut
        Query memory queryDirect = queryNoSplit(_amountIn, _tokenIn, _tokenOut);

        if (queryDirect.amountOut != 0) {
            if (withGas) {
                gasEstimate = IAdapter(queryDirect.adapter).swapGasEstimate();
            }
            bestOption.addToTail(queryDirect.amountOut, queryDirect.adapter, queryDirect.tokenOut, gasEstimate);
            bestAmountOut = queryDirect.amountOut;
        }
        // Only check the rest if they would go beyond step limit (Need at least 2 more steps)
        if (_maxSteps > 1 && _queries.adapters.length / 32 <= _maxSteps - 2) {
            // Check for paths that pass through trusted tokens
            for (uint256 i = 0; i < TRUSTED_TOKENS.length; i++) {
                if (_tokenIn == TRUSTED_TOKENS[i]) {
                    continue;
                }
                // Loop through all adapters to find the best one for swapping tokenIn for one of the trusted tokens
                Query memory bestSwap = queryNoSplit(_amountIn, _tokenIn, TRUSTED_TOKENS[i]);
                if (bestSwap.amountOut == 0) {
                    continue;
                }
                // Explore options that connect the current path to the tokenOut
                Offer memory newOffer = _queries.clone();
                if (withGas) {
                    gasEstimate = IAdapter(bestSwap.adapter).swapGasEstimate();
                }
                newOffer.addToTail(bestSwap.amountOut, bestSwap.adapter, bestSwap.tokenOut, gasEstimate);
                newOffer = _findBestPath(
                    bestSwap.amountOut,
                    TRUSTED_TOKENS[i],
                    _tokenOut,
                    _maxSteps,
                    newOffer,
                    _tknOutPriceNwei
                ); // Recursive step
                address tokenOut = newOffer.getTokenOut();
                uint256 amountOut = newOffer.getAmountOut();
                // Check that the last token in the path is the tokenOut and update the new best option if neccesary
                if (_tokenOut == tokenOut && amountOut > bestAmountOut) {
                    if (newOffer.gasEstimate > bestOption.gasEstimate) {
                        uint256 gasCostDiff = (_tknOutPriceNwei * (newOffer.gasEstimate - bestOption.gasEstimate)) /
                            1e9;
                        uint256 priceDiff = amountOut - bestAmountOut;
                        if (gasCostDiff > priceDiff) {
                            continue;
                        }
                    }
                    bestAmountOut = amountOut;
                    bestOption = newOffer;
                }
            }
        }
        return bestOption;
    }

    // -- SWAPPERS --

    function _swapNoSplit(
        Trade calldata _trade,
        address _from,
        address _to,
        uint256 _fee
    ) internal returns (uint256) {
        uint256[] memory amounts = new uint256[](_trade.path.length);
        if (_fee > 0 || MIN_FEE > 0) {
            // Transfer fees to the claimer account and decrease initial amount
            amounts[0] = _applyFee(_trade.amountIn, _fee);
            _collectFee(_trade.path[0], _from, _trade.amountIn - amounts[0]);
        } else {
            amounts[0] = _trade.amountIn;
        }
        _transferFrom(_trade.path[0], _from, _trade.adapters[0], amounts[0]);
        // Get amounts that will be swapped
        for (uint256 i = 0; i < _trade.adapters.length; i++) {
            amounts[i + 1] = IAdapter(_trade.adapters[i]).query(amounts[i], _trade.path[i], _trade.path[i + 1]);
        }
        require(amounts[amounts.length - 1] >= _trade.amountOut, "MoksaRouter: Insufficient output amount");
        for (uint256 i = 0; i < _trade.adapters.length; i++) {
            // All adapters should transfer output token to the following target
            // All targets are the adapters, expect for the last swap where tokens are sent out
            address targetAddress = i < _trade.adapters.length - 1 ? _trade.adapters[i + 1] : _to;
            IAdapter(_trade.adapters[i]).swap(
                amounts[i],
                amounts[i + 1],
                _trade.path[i],
                _trade.path[i + 1],
                targetAddress
            );
        }
        emit MoksaSwap(_trade.path[0], _trade.path[_trade.path.length - 1], _trade.amountIn, amounts[amounts.length - 1]);
        return amounts[amounts.length - 1];
    }

    function swapNoSplit(
        Trade calldata _trade,
        address _to,
        uint256 _fee
    ) override public {
        _swapNoSplit(_trade, msg.sender, _to, _fee);
    }

    function swapNoSplitFromNative(
        Trade calldata _trade,
        address _to,
        uint256 _fee
    ) override external payable {
        require(_trade.path[0] == WNATIVE, "MoksaRouter: Path needs to begin with wrapped native");
        _wrap(_trade.amountIn);
        _swapNoSplit(_trade, address(this), _to, _fee);
    }

    function swapNoSplitToNative(
        Trade calldata _trade,
        address _to,
        uint256 _fee
    ) override public {
        require(_trade.path[_trade.path.length - 1] == WNATIVE, "MoksaRouter: Path needs to end with wrapped native");
        uint256 returnAmount = _swapNoSplit(_trade, msg.sender, address(this), _fee);
        _unwrap(returnAmount);
        _returnTokensTo(NATIVE, returnAmount, _to);
    }

    /**
     * Swap token to token without the need to approve the first token
     */
    function swapNoSplitWithPermit(
        Trade calldata _trade,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) override external {
        IERC20(_trade.path[0]).permit(msg.sender, address(this), _trade.amountIn, _deadline, _v, _r, _s);
        swapNoSplit(_trade, _to, _fee);
    }

    /**
     * Swap token to native without the need to approve the first token
     */
    function swapNoSplitToNativeWithPermit(
        Trade calldata _trade,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) override external {
        IERC20(_trade.path[0]).permit(msg.sender, address(this), _trade.amountIn, _deadline, _v, _r, _s);
        swapNoSplitToNative(_trade, _to, _fee);
    }
}
