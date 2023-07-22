// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Import Lyra contracts
import {IOptionMarket} from "@lyra-protocol/contracts/interfaces/IOptionMarket.sol";
import {OptionManager} from "./OptionManager.sol";

contract OptionChoice is OptionManager {
    function whichStrike(uint256 _spotPrice) public view returns (uint256) {
        // Get the list of strikes for the given board

        return _spotPrice;
    }
}
