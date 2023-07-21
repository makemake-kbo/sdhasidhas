pragma solidity 0.8.16;

import {LyraAdapter} from "@lyra-protocol/contracts/periphery/LyraAdapter.sol";

contract OptionManager is LyraAdapter {
    constructor() LyraAdapter();

    uint256[] public activePositionIds;

    function initAdapter(address _lyraRegistry, address _optionMarket, address _curveSwap, address _feeCounter)
        external
    {
        // set addresses for LyraAdapter
        setLyraAddresses(_lyraRegistry, _optionMarket, _curveSwap, _feeCounter);
    }

    function openNewLyraPosition(uint256 strikeId, uint256 amount) external returns(uint256){
        TradeInputParameters tradeParams = TradeInputParameters({
            strikeId: strikeId,
            positionId: 0, // if 0, new position is created
            iterations: 3, // more iterations use more gas but incur less slippage
            optionType: LONG_CALL,
            amount: amount,
            setCollateralTo: 0, // 0 if longing
            minTotalCost: 0,
            maxTotalCost: type(uint256).max
        });
        TradeResult result = _openPosition(tradeParams); // built-in LyraAdapter.sol function
        activePositionIds.push(result.positionId);

        return result.positionId;
    }

    function modifyLyraPosition(uint256 positionId, uint256 amount) external {
        Position position = _getPositions(_singletonArray(positionId)); // must first convert number into a static array

        TradeInputParameters tradeParams = TradeInputParameters({
            strikeId: position.strikeId,
            positionId: position.positionId,
            iterations: 3,
            optionType: position.optionType,
            amount: amount, // set the amount of options we need to buy
            setCollateralTo: 0, // change collateral by addCollatAmount, 0 since we gigalong
            minTotalCost: 0,
            maxTotalCost: type(uint256).max // assume we are ok with any premium amount
        });

        // built-in LyraAdapter.sol functions
        _closeOrForceClosePosition(tradeParams);
    }
}
