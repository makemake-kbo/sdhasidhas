// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Import Lyra contracts
import {IOptionMarket} from "@lyra-protocol/contracts/interfaces/IOptionMarket.sol";
import {OptionManager} from "./OptionManager.sol";

contract OptionChoice is OptionManager {
    uint256 options;

    constructor(address _optionMarket) {
        optionMarket = IOptionMarket(_optionMarket);
    }

    function howManyOptions(uint256 _liquidityChange) public view returns (uint256) {
        // The number of options to buy is equal to the change in liquidity on deposit minus the options already in the basket
        return _liquidityChange - options;
    }

    function getBoardId(uint256 _expiryDate) public view returns (uint256) {
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

    function whichStrike(uint256 _spotPrice) public view returns (uint256) {
        // Get the list of strikes for the given board

        return _spotPrice;
    }
}
