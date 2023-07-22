pragma solidity ^0.8.0;

import {LyraAdapter, DecimalMath} from "@lyra-protocol/contracts/periphery/LyraAdapter.sol";
import "@lyra-protocol/contracts/interfaces/IOptionMarketPricer.sol";

contract OptionManager is LyraAdapter {
    uint256[] public activePositionIds;

    function initAdapter(
        address _lyraRegistry,
        address _optionMarket,
        address _curveSwap,
        address _feeCounter
    ) external {
        // set addresses for LyraAdapter
        setLyraAddresses(_lyraRegistry, _optionMarket, _curveSwap, _feeCounter);
    }

    function modifyLyraPosition(
        uint256 positionId,
        uint256 amount,
        uint256 collateral
    ) external onlyOwner {
        LyraAdapter.OptionPosition[] memory positions = _getPositions(
            _singletonArray(positionId)
        ); // must first convert number into a static array
        // Position position = _getPositions(_singletonArray(positionId)); // must first convert number into a static array

        LyraAdapter.OptionPosition memory position = positions[0];

        TradeInputParameters memory tradeParams = TradeInputParameters({
            strikeId: position.strikeId,
            positionId: position.positionId,
            iterations: 3,
            optionType: position.optionType,
            amount: amount, // closing 100%
            setCollateralTo: collateral, // increase collateral by addCollatAmount
            minTotalCost: 0,
            maxTotalCost: type(uint256).max, // assume we are ok with any premium amount
            rewardRecipient: address(0)
        });

        // built-in LyraAdapter.sol functions
        _closeOrForceClosePosition(tradeParams);
    }

    function _singletonArray(
        uint256 val
    ) public view returns (uint256[] memory arr) {
        arr = new uint256[](1);
        arr[0] = val;
        return arr;
    }

    function openNewLyraPosition(
        uint256 strikeId,
        uint256 amount
    ) public returns (uint256) {
        TradeInputParameters memory tradeParams = TradeInputParameters({
            strikeId: strikeId,
            positionId: 0, // if 0, new position is created
            iterations: 3, // more iterations use more gas but incur less slippage
            optionType: LyraAdapter.OptionType.LONG_CALL,
            amount: amount,
            setCollateralTo: 0, // 0 if longing
            minTotalCost: 0,
            maxTotalCost: type(uint256).max,
            rewardRecipient: address(0)
        });
        TradeResult memory result = _openPosition(tradeParams); // built-in LyraAdapter.sol function
        activePositionIds.push(result.positionId);

        return result.positionId;
    }

    function isOptionExpired(uint256 strikeId) public view returns (bool) {
        // logic taken from LyraAdapter.sol l:270
        return
            _isOutsideDeltaCutoff(strikeId) || _isWithinTradingCutoff(strikeId);
    }
}
