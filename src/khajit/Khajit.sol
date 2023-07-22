pragma solidity ^0.8.0;

/**
 * Kahjit has options if you have coin
 */
contract Kahjit {

	struct KahjitOption {
		uint64 strike;
		uint64 expiry;
		uint64 price;
		bool isCall;
	}

	struct Position {
		uint256 amount;
		KahjitOption option;
	}

	mapping (address => Position) public positions;

	function buyOptions (uint256 _amount, uint64 _strike, uint64 _expiry, uint64 _price, bool _isCall) public returns(uint256) {
		if (positions[msg.sender].amount > 0) {
			positions[msg.sender].amount += _amount;

			return positions[msg.sender].amount;
		}

		KahjitOption memory option = KahjitOption(_strike, _expiry, _price, _isCall);
		positions[msg.sender] = Position(_amount, option);

		return positions[msg.sender].amount;

	}

	function sellOptions (uint256 _amount, uint64 _strike, uint64 _expiry, uint64 _price, bool _isCall) public returns(uint256) {
		if (positions[msg.sender].amount - _amount <= 0) {
			delete positions[msg.sender];
			return 0;
		}

		positions[msg.sender].amount -= _amount;
		return positions[msg.sender].amount;
	}
}
