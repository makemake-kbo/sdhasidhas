// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Import Lyra contracts
import {IOptionMarket} from "@lyra-protocol/contracts/interfaces/IOptionMarket.sol";
import {OptionManager} from "./OptionManager.sol";

contract OptionChoice is OptionManager {
    constructor(address _optionMarket) {
        optionMarket = IOptionMarket(_optionMarket);
    }

    function howManyOptions(uint256 _liquidityChange) public view returns (uint256) {
        // The number of options to buy is equal to the change in liquidity
        return _liquidityChange;
    }

    function getBoardId(uint256 _expiryDate) external view returns (uint256) {
        // Get the list of live boards
        uint256[] memory liveBoards = optionMarket.getLiveBoards();

        // Check if there are any live boards
        require(liveBoards.length > 0, "No live boards available");

        // Find the board with the closest expiry date that is greater than or equal to the given date
        uint256 boardId = liveBoards[0];
        // Careful with for loops in solidity. If the array is too large you can tun out of gas in the middle of transaction and get stuck.
        for (uint256 i = 1; i < liveBoards.length; i++) {
            uint256 expiry = optionMarket.getOptionBoard(liveBoards[i]).expiry;
            if (expiry >= _expiryDate && expiry < optionMarket.getOptionBoard(boardId).expiry) {
                boardId = liveBoards[i];
            }
        }

        return boardId;
    }

    function whichStrike(uint256 _spotPrice, uint256 boardId) public view returns (uint256) {
        // Get the list of strikes for the given board
        uint256[] memory strikes = optionMarket.getBoardStrikes(boardId);

        // Check if there are any strikes available
        require(strikes.length > 0, "No strikes available for the given board");

        // Determine the strike price based on your logic
        uint256 strike = _spotPrice + ((_spotPrice * 3) / 10); // careful with division by integer. Solidity truncates the value.

        // Find the strike that is closest to but not less than the calculated strike
        uint256 strikeToBuy = strikes[0];
        // Careful with for loops in solidity. If the array is too large you can tun out of gas in the middle of transaction and get stuck.
        for (uint256 i = 1; i < strikes.length; i++) {
            uint256 strikePrice = optionMarket.getStrike(strikes[i]).strikePrice;
            if (strikePrice >= strike && strikePrice < optionMarket.getStrike(strikeToBuy).strikePrice) {
                strikeToBuy = strikes[i];
            }
        }

        return strikeToBuy;
    }
}
