// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../interface/IERC20.sol";
import "../interface/IWETH.sol";
import "../interface/IKuruOrderBook.sol";
import "../lib/SafeERC20.sol";
import "../MoksaAdapter.sol";

contract KuruAdapter is MoksaAdapter {
    using SafeERC20 for IERC20;

    event UpdatedMonAusdMarket(address indexed oldMarket, address indexed newMarket);
    event UpdatedMonUsdcMarket(address indexed oldMarket, address indexed newMarket);

    uint256 private constant BPS = 10_000;

    struct KuruMarketParams {
        uint256 pricePrecision;
        uint256 sizePrecision;
        uint256 baseAssetDecimals;
        uint256 quoteAssetDecimals;
        uint256 takerFeeBps;
    }

    address public wmon;
    address public ausd;
    address public usdc;
    address public monAusdMarket;
    address public monUsdcMarket;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        uint256 _swapGasEstimate,
        address _wmon,
        address _ausd,
        address _usdc,
        address _monAusdMarket,
        address _monUsdcMarket,
        address _initialMaintainer
    ) external initializer {
        __MoksaAdapter_init(_name, _swapGasEstimate, _initialMaintainer);
        wmon = _wmon;
        ausd = _ausd;
        usdc = _usdc;
        _setMonAusdMarket(_monAusdMarket);
        _setMonUsdcMarket(_monUsdcMarket);
    }

    function setMonAusdMarket(address _monAusdMarket) external onlyMaintainer {
        _setMonAusdMarket(_monAusdMarket);
    }

    function setMonUsdcMarket(address _monUsdcMarket) external onlyMaintainer {
        _setMonUsdcMarket(_monUsdcMarket);
    }

    function _setMonAusdMarket(address _monAusdMarket) internal {
        require(_monAusdMarket != address(0), "KuruAdapter: zero MON/AUSD market");
        address oldMarket = monAusdMarket;
        if (oldMarket != address(0) && oldMarket != _monAusdMarket) {
            IERC20(ausd).safeApprove(oldMarket, 0);
        }
        if (oldMarket != _monAusdMarket) {
            IERC20(ausd).safeApprove(_monAusdMarket, 0);
            IERC20(ausd).safeApprove(_monAusdMarket, UINT_MAX);
            monAusdMarket = _monAusdMarket;
            emit UpdatedMonAusdMarket(oldMarket, _monAusdMarket);
        }
    }

    function _setMonUsdcMarket(address _monUsdcMarket) internal {
        require(_monUsdcMarket != address(0), "KuruAdapter: zero MON/USDC market");
        address oldMarket = monUsdcMarket;
        if (oldMarket != address(0) && oldMarket != _monUsdcMarket) {
            IERC20(usdc).safeApprove(oldMarket, 0);
        }
        if (oldMarket != _monUsdcMarket) {
            IERC20(usdc).safeApprove(_monUsdcMarket, 0);
            IERC20(usdc).safeApprove(_monUsdcMarket, UINT_MAX);
            monUsdcMarket = _monUsdcMarket;
            emit UpdatedMonUsdcMarket(oldMarket, _monUsdcMarket);
        }
    }

    function _query(uint256 _amountIn, address _tokenIn, address _tokenOut) internal view override returns (uint256) {
        if (_amountIn == 0 || _tokenIn == _tokenOut) {
            return 0;
        }

        (address market, bool sellsBase) = _getMarket(_tokenIn, _tokenOut);
        if (market == address(0)) {
            return 0;
        }

        KuruMarketParams memory params = _readMarketParams(market);

        bytes memory l2Book = IKuruOrderBook(market).getL2Book();
        if (l2Book.length < 32) {
            return 0;
        }

        if (sellsBase) {
            uint256 sizeInPrecision = (_amountIn * params.sizePrecision) / (10 ** params.baseAssetDecimals);
            if (sizeInPrecision == 0) {
                return 0;
            }

            uint256 grossAmountOut = _quoteSellFromBids(
                l2Book, sizeInPrecision, params.sizePrecision, params.pricePrecision, params.quoteAssetDecimals
            );
            return (grossAmountOut * (BPS - params.takerFeeBps)) / BPS;
        }

        uint256 grossBaseOut = _quoteBuyFromAsks(
            l2Book,
            _amountIn,
            params.sizePrecision,
            params.pricePrecision,
            params.baseAssetDecimals,
            params.quoteAssetDecimals
        );
        return (grossBaseOut * (BPS - params.takerFeeBps)) / BPS;
    }

    function _swap(uint256 _amountIn, uint256 _amountOut, address _tokenIn, address _tokenOut, address _to) internal override {
        (address market, bool sellsBase) = _getMarket(_tokenIn, _tokenOut);
        require(market != address(0), "KuruAdapter: unsupported pair");

        KuruMarketParams memory params = _readMarketParams(market);

        if (sellsBase) {
            uint256 sizeInPrecision = (_amountIn * params.sizePrecision) / (10 ** params.baseAssetDecimals);
            require(sizeInPrecision <= type(uint96).max && sizeInPrecision > 0, "KuruAdapter: invalid size");

            uint256 toBalBefore = IERC20(_tokenOut).balanceOf(_to);
            uint256 adapterBalBefore = IERC20(_tokenOut).balanceOf(address(this));

            IWETH(wmon).withdraw(_amountIn);
            IKuruOrderBook(market).placeAndExecuteMarketSell{value: _amountIn}(uint96(sizeInPrecision), _amountOut, false, false);

            uint256 amountOutReceived = IERC20(_tokenOut).balanceOf(address(this)) - adapterBalBefore;
            _returnTo(_tokenOut, amountOutReceived, _to);

            require(IERC20(_tokenOut).balanceOf(_to) - toBalBefore >= _amountOut, "KuruAdapter: insufficient amount out");
            return;
        }

        uint256 quoteInPrecision = (_amountIn * params.pricePrecision) / (10 ** params.quoteAssetDecimals);
        require(quoteInPrecision <= type(uint96).max && quoteInPrecision > 0, "KuruAdapter: invalid quote size");

        uint256 nativeBalBefore = address(this).balance;
        IKuruOrderBook(market).placeAndExecuteMarketBuy(uint96(quoteInPrecision), _amountOut, false, false);
        uint256 nativeReceived = address(this).balance - nativeBalBefore;
        require(nativeReceived > 0, "KuruAdapter: no native out");

        IWETH(wmon).deposit{value: nativeReceived}();
        _returnTo(_tokenOut, nativeReceived, _to);
    }

    function _quoteSellFromBids(
        bytes memory _book,
        uint256 _sizeInPrecision,
        uint256 _sizePrecision,
        uint256 _pricePrecision,
        uint256 _quoteAssetDecimals
    ) private pure returns (uint256 amountOut) {
        uint256 offset = 32;
        uint256 len = _book.length;
        uint256 remainingSize = _sizeInPrecision;

        while (offset + 64 <= len && remainingSize > 0) {
            uint256 price = _readWord(_book, offset);
            offset += 32;
            if (price == 0) {
                break;
            }

            uint256 size = _readWord(_book, offset);
            offset += 32;

            uint256 fill = size < remainingSize ? size : remainingSize;
            remainingSize -= fill;

            uint256 quoteFill = (fill * price * (10 ** _quoteAssetDecimals)) / (_sizePrecision * _pricePrecision);
            amountOut += quoteFill;
        }
    }

    function _quoteBuyFromAsks(
        bytes memory _book,
        uint256 _quoteAmountIn,
        uint256 _sizePrecision,
        uint256 _pricePrecision,
        uint256 _baseAssetDecimals,
        uint256 _quoteAssetDecimals
    ) private pure returns (uint256 amountOut) {
        uint256 offset = 32;
        uint256 len = _book.length;

        while (offset + 64 <= len) {
            uint256 bidPrice = _readWord(_book, offset);
            offset += 32;
            if (bidPrice == 0) {
                break;
            }
            offset += 32;
        }

        uint256 remainingQuote = _quoteAmountIn;
        while (offset + 64 <= len && remainingQuote > 0) {
            uint256 askPrice = _readWord(_book, offset);
            offset += 32;
            if (askPrice == 0) {
                break;
            }

            uint256 askSize = _readWord(_book, offset);
            offset += 32;

            uint256 fullLevelQuote = (askSize * askPrice * (10 ** _quoteAssetDecimals)) / (_sizePrecision * _pricePrecision);
            if (fullLevelQuote == 0) {
                continue;
            }

            if (remainingQuote >= fullLevelQuote) {
                remainingQuote -= fullLevelQuote;
                amountOut += (askSize * (10 ** _baseAssetDecimals)) / _sizePrecision;
            } else {
                uint256 partialSize = (remainingQuote * _sizePrecision * _pricePrecision) / (askPrice * (10 ** _quoteAssetDecimals));
                amountOut += (partialSize * (10 ** _baseAssetDecimals)) / _sizePrecision;
                remainingQuote = 0;
            }
        }
    }

    function _readWord(bytes memory _data, uint256 _offset) private pure returns (uint256 word) {
        assembly {
            word := mload(add(add(_data, 0x20), _offset))
        }
    }

    function _getMarket(address _tokenIn, address _tokenOut) private view returns (address market, bool sellsBase) {
        if (_tokenIn == wmon && _tokenOut == ausd) {
            return (monAusdMarket, true);
        }
        if (_tokenIn == ausd && _tokenOut == wmon) {
            return (monAusdMarket, false);
        }
        if (_tokenIn == wmon && _tokenOut == usdc) {
            return (monUsdcMarket, true);
        }
        if (_tokenIn == usdc && _tokenOut == wmon) {
            return (monUsdcMarket, false);
        }
        return (address(0), false);
    }

    function _readMarketParams(address _market) private view returns (KuruMarketParams memory params) {
        (
            uint32 pricePrecision,
            uint96 sizePrecision,
            ,
            uint256 baseAssetDecimals,
            ,
            uint256 quoteAssetDecimals,
            ,
            ,
            ,
            uint256 takerFeeBps,

        ) = IKuruOrderBook(_market).getMarketParams();

        params.pricePrecision = uint256(pricePrecision);
        params.sizePrecision = uint256(sizePrecision);
        params.baseAssetDecimals = baseAssetDecimals;
        params.quoteAssetDecimals = quoteAssetDecimals;
        params.takerFeeBps = takerFeeBps;
    }
}
