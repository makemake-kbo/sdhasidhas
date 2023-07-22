pragma solidity ^0.8.0;

interface IKahjit {
	function buyOptions (uint256 _amount, uint64 _strike, uint64 _expiry, uint64 _price, bool _isCall) external returns(uint256);
	function sellOptions (uint256 _amount, uint64 _strike, uint64 _expiry, uint64 _price, bool _isCall) external returns(uint256);
	function isExpired () external view returns(bool);
}