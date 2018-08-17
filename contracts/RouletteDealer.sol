pragma solidity ^0.4.2;

import "./RouletteTable.sol";

contract RouletteDealer {

    uint8 constant private BLOCKS_TO_BET = 5;

    uint8 constant private BLOCKS_TO_SPIN = 1;

    uint256 private entropy;

    address public creator;

    address public rouletteTable;

    bool public initialized;

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    modifier onlyIfInitialized() {
        require(initialized);
        _;
    }

    constructor() public {
        creator = msg.sender;
    }

    // Tip the dealer functionality
    function() public {
        revert();
    }

    function initialize(address _rouletteTable) public
    onlyCreator
    returns (bool){
        if (!initialized && rouletteTable == address(0)) {
            rouletteTable = _rouletteTable;
            initialized = true;
        }
        return initialized && rouletteTable == _rouletteTable;
    }

    function work() public
    onlyIfInitialized
    returns (bool) {
        (uint256 id, uint256 bettingOpenedAt, uint256 bettingClosedAt, uint256 wheelSpunAt, uint8 winner, uint256 totalBet, uint256 totalLost, uint256 totalWon) = RouletteTable(rouletteTable).currentSpin();

        if (wheelSpunAt != 0) {
            require(RouletteTable(rouletteTable).openBetting());
        } else if (bettingClosedAt == 0 && totalBet > 0 && block.number >= bettingOpenedAt + BLOCKS_TO_BET) {
            require(RouletteTable(rouletteTable).closeBetting());
        } else if (bettingClosedAt != 0 && totalBet > 0 && block.number >= bettingClosedAt + BLOCKS_TO_SPIN) {
            uint8 winner_ = RouletteTable(rouletteTable).spinWheel(entropy);
            require(RouletteTable(rouletteTable).markWinner(winner_));
        }

        entropy += (now + block.number + block.difficulty);
        return true;
    }
}