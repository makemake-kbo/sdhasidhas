pragma solidity ^0.8.0;

/**
 * Generic interface to buy and sell options
 * May need some adaptations to make it work with other protocols
 * (works as long as you have coins)
 */
interface IOptions {
    /// @notice buy some options
    function buyOptions(address to, uint256 amount, uint64 strike, uint64 expiry, uint64 price, bool isCall)
        external
        returns (uint256);

    /// @notice sell some options
    function sellOptions(uint256 index) external returns (uint256);
}
