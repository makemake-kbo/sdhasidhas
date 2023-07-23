pragma solidity ^0.8.0;

import "src/options/IOptions.sol";

error NoOptions();
error NotExpired();

/// @param amount how much of options have been bought
struct KahjitOption {
    uint256 amount;
    uint64 strike;
    uint64 expiry;
    uint64 price;
    bool isCall;
}

contract Opt is IOptions {
    // user => positions((total_amount, options))
    mapping(address => KahjitOption[]) public options;

    constructor() {}

    /// @return new amount after buy
    function buyOptions(address to, uint256 amount, uint64 strike, uint64 expiry, uint64 price, bool isCall)
        external
        virtual
        returns (uint256)
    {
        KahjitOption memory option = KahjitOption(amount, strike, expiry, price, isCall);
        options[to].push(option);

        return option.amount;
    }

    // @notice I want to sell one of my previously bought options
    function sellOptions(uint256 index) external virtual returns (uint256) {
        uint256 max = options[msg.sender].length;
        if (max == 0) revert NoOptions();

        // remove the option at index by replace and pop
        options[msg.sender][max - 1] = options[msg.sender][index];
        KahjitOption memory removedOption = options[msg.sender][max - 1];
        options[msg.sender].pop();

        return removedOption.amount;
    }
}

/**
 * Kahjit has options if you have coin
 */
contract Kahjit is Opt {
    constructor() Opt() {}

    /// @notice do stuff on expired option
    function pokeOption(address who, uint256 index) external {
        if (!isExpired(who, index)) revert NotExpired();
    }

    function isExpired(address who, uint256 index) public view returns (bool) {
        return block.timestamp > options[who][index].expiry;
    }
}
