pragma solidity 0.8.16;

import {LyraAdapter} from "@lyra-protocol/contracts/periphery/LyraAdapter.sol";
import {OptionMarket} from "@lyra-protocol/contracts/OptionMarket.sol";
import {IOptionMarket} from "@lyra-protocol/contracts/interfaces/IOptionMarket.sol";
import {IOptionToken} from "@lyra-protocol/contracts/interfaces/IOptionToken.sol";

contract TraderExample is LyraAdapter {
    constructor() LyraAdapter() {}

    uint[] public activePositionIds;

    function initAdapter(
    address _lyraRegistry,
    address _optionMarket,
    address _curveSwap,
    address _feeCounter
    ) external onlyOwner {
    // set addresses for LyraAdapter
    setLyraAddresses(_lyraRegistry, _optionMarket, _curveSwap, _feeCounter);
    }

    function initAdapter(address _lyraRegistry, address _optionMarket, address _curveSwap, address _feeCounter)
        external
    {
        // set addresses for LyraAdapter
        setLyraAddresses(_lyraRegistry, _optionMarket, _curveSwap, _feeCounter);
    }

    function modifyLyraPosition(uint positionId, uint amount, uint collateral) external onlyOwner{
      IOptionToken.OptionPosition[] memory position = _getPositions(_singletonArray(positionId)); // must first convert number into a static array
      // Position position = _getPositions(_singletonArray(positionId)); // must first convert number into a static array

      TradeInputParameters memory tradeParams = TradeInputParameters({
        strikeId: position.strikeId,
        positionId: position.positionId,
        iterations: 3,
        optionType: position.optionType,
        amount: amount, // closing 100%
        setCollateralTo: collateral, // increase collateral by addCollatAmount
        minTotalCost: 0,
        maxTotalCost: type(uint).max // assume we are ok with any premium amount
      });

      // built-in LyraAdapter.sol functions
      _closeOrForceClosePosition(tradeParams);
    }

    function modifyLyraPosition(uint256 positionId, uint256 amount, uint256 collateral) external {
        Position position = _getPositions(_singletonArray(positionId)); // must first convert number into a static array

        TradeInputParameters tradeParams = TradeInputParameters({
            strikeId: position.strikeId,
            positionId: position.positionId,
            iterations: 3,
            optionType: position.optionType,
            amount: amount, // closing 100%
            setCollateralTo: collateral, // increase collateral by addCollatAmount
            minTotalCost: 0,
            maxTotalCost: type(uint256).max // assume we are ok with any premium amount
        });

        // built-in LyraAdapter.sol functions
        _closeOrForceClosePosition(tradeParams);
    }

}
