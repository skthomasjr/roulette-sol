pragma solidity ^0.4.2;

import "./Casino.sol";
import "./RouletteDealer.sol";

contract RouletteTable {

    struct Bet {
        uint8 id;
        uint8 payout;
        uint256 wagerCount;
        mapping(uint256 => Wager) wagers;
        mapping(uint8 => bool) outcome;
    }

    struct Bettor {
        uint256 index;
        address account;
        uint256 balance;
    }

    struct Pocket {
        uint8 id;
        Bet[] bets;
    }

    struct Spin {
        uint256 id;
        uint256 bettingOpenedAt;
        uint256 bettingClosedAt;
        uint256 wheelSpunAt;
        uint8 winner;
        uint256 totalBet;
        uint256 totalLost;
        uint256 totalWon;
    }

    struct Wager {
        address bettor;
        uint256 amount;
    }

    uint256 constant private MAX_UINT256 = 2 ** 256 - 1;

    bool private initializedBets;
    bool private initializedCasino;
    bool private initializedDealer;
    bool private initializedRules;
    bool private initializedPockets;
    uint8 private lastWinner;
    uint8 private totalUniqueBets;

    address public casino;
    address public creator;
    address public dealer;
    bool public initialized;
    uint256 public bettorCount;
    uint256 public spinCount;
    uint256 public totalBettorSupply;
    Spin public currentSpin_;

    mapping(address => Bettor) public bettors;

    mapping(uint8 => Bet) public bets;

    mapping(uint8 => Pocket) public pockets;

    mapping(uint256 => address) public bettorAccounts;

    mapping(uint256 => Spin) public spins;

    modifier notInitialized {
        require(!initialized);
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    modifier onlyDealer() {
        require(msg.sender == dealer);
        _;
    }

    modifier onlyIfBettingClosed() {
        require(currentSpin_.bettingOpenedAt != 0 && currentSpin_.bettingClosedAt != 0);
        _;
    }

    modifier onlyIfBettingOpen() {
        require(currentSpin_.bettingOpenedAt != 0 && currentSpin_.bettingClosedAt == 0);
        _;
    }

    modifier onlyIfInitialized {
        require(initialized);
        _;
    }

    constructor() public {
        creator = msg.sender;
    }

    function() public payable
    {
        if (msg.sender != casino) {
            require(increaseBalance(msg.sender, msg.value));
        }
    }

    function bettorOf(address _account) public view
    returns (uint256 index, address account, uint256 balance) {
        Bettor storage bettor = bettors[_account];
        return (bettor.index, bettor.account, bettor.balance);
    }

    function currentSpin() public view
    returns(uint256 id, uint256 bettingOpenedAt, uint256 bettingClosedAt, uint256 wheelSpunAt, uint8 winner, uint256 totalBet, uint256 totalLost, uint256 totalWon) {
        return (currentSpin_.id, currentSpin_.bettingOpenedAt, currentSpin_.bettingClosedAt, currentSpin_.wheelSpunAt, currentSpin_.winner, currentSpin_.totalBet, currentSpin_.totalLost, currentSpin_.totalWon);
    }

    function addBet(uint8 _id, uint8 _payout, string) public
    notInitialized
    onlyCreator
    returns (bool) {
        totalUniqueBets++;
        Bet storage bet = bets[_id];
        bet.id = _id;
        bet.payout = _payout;
        return true;
    }

    function addRule(uint8 _wheelPocket, uint8 _bet, string) public
    notInitialized
    onlyCreator
    returns (bool) {
        pockets[_wheelPocket].bets.push(bets[_bet]);
        bets[_bet].outcome[_wheelPocket] = true;
        return true;
    }

    function addWheelPocket(uint8 _id) private
    notInitialized
    onlyCreator
    returns (bool) {
        Pocket storage pocket = pockets[_id];
        pocket.id = _id;
        return true;
    }

    function closeBetting() public
    onlyIfInitialized
    onlyDealer
    onlyIfBettingOpen
    returns (bool) {
        currentSpin_.bettingClosedAt = block.number;
        return true;
    }

    function initializeBets() public
    onlyCreator
    returns (bool) {
        if (!initialized && !initializedBets) {
            addBets();
            initializedBets = true;
            initialized = initializedCasino && initializedDealer && initializedPockets && initializedBets && initializedRules;
        }
        return initializedBets;
    }

    function initializeCasino(address _casino) public
    onlyCreator
    returns (bool) {
        if (!initialized && !initializedCasino) {
            casino = _casino;
            initializedCasino = true;
            initialized = initializedCasino && initializedDealer && initializedPockets && initializedBets && initializedRules;
        }
        return initializedCasino;
    }

    function initializeDealer(address _dealer) public
    onlyCreator
    returns (bool) {
        if (!initialized && !initializedDealer) {
            dealer = _dealer;
            initializedDealer = true;
            initialized = initializedCasino && initializedDealer && initializedPockets && initializedBets && initializedRules;
        }
        return initializedDealer;
    }

    function initializeRules() public
    onlyCreator
    returns (bool) {
        if (!initialized && !initializedRules) {
            addRules();
            initializedRules = true;
            initialized = initializedCasino && initializedDealer && initializedPockets && initializedBets && initializedRules;
        }
        return initializedRules;
    }

    function initializePockets() public
    onlyCreator
    returns (bool) {
        if (!initialized && !initializedPockets) {
            addWheelPockets();
            initializedPockets = true;
            initialized = initializedCasino && initializedDealer && initializedPockets && initializedBets && initializedRules;
        }
        return initializedPockets;
    }

    function nudgeDealer() public
    returns (bool) {
        require(RouletteDealer(dealer).work());
        return true;
    }

    function openBetting() public
    onlyIfInitialized
    onlyDealer
    returns (bool) {
        uint256 spinIndex = spinCount++;
        spins[spinIndex] = Spin(spinIndex, block.number, 0, 0, 0, 0, 0, 0);
        currentSpin_ = spins[spinIndex];
        return true;
    }

    function liquidate() public
    onlyIfInitialized
    returns (bool) {
        Bettor storage bettor = bettors[msg.sender];
        uint256 fundsToLiquidate = bettor.balance;
        require(decreaseBalance(bettor.account, fundsToLiquidate));
        require(msg.sender.send(fundsToLiquidate));
        return true;
    }

    function pullBets() public
    onlyIfInitialized
    onlyIfBettingOpen
    returns (bool) {
        for (uint8 betID = 1; betID <= totalUniqueBets; betID ++) {
            Bet storage bet = bets[betID];
            for (uint256 wagerIndex = 0; wagerIndex < bet.wagerCount; wagerIndex ++) {
                Wager storage wager = bet.wagers[wagerIndex];
                if (wager.bettor == msg.sender) {
                    require(increaseBalance(msg.sender, wager.amount));
                    currentSpin_.totalBet -= wager.amount;
                    wager.amount = 0;
                }
            }
        }
        return true;
    }

    function spinWheel(uint256 _entropy) public
    onlyIfInitialized
    onlyDealer
    returns (uint8) {
        spinCount ++;
        return uint8(randomRange(bytes32(spinCount + _entropy), 37)) + 1;
    }

    function markWinner(uint8 winner) public
    onlyIfInitialized
    onlyDealer
    onlyIfBettingClosed
    returns (bool) {
        require(winner >= 1 && winner <= 38);
        currentSpin_.winner = winner;
        currentSpin_.wheelSpunAt = block.number;
        require(processBets());
        require(processRevenue());
        return true;
    }

    function wager(uint8 _betID, uint256 _amount) public
    onlyIfInitialized
    onlyIfBettingOpen
    returns (bool) {
        require(currentSpin_.bettingOpenedAt != 0);
        require(currentSpin_.bettingClosedAt == 0);
        require(decreaseBalance(msg.sender, _amount));
        Bet storage bet = bets[_betID];
        bet.wagers[bet.wagerCount++] = Wager(msg.sender, _amount);
        currentSpin_.totalBet += _amount;
        return true;
    }

    function withdraw(uint256 _amount) public
    onlyIfInitialized
    returns (bool) {
        Bettor storage bettor = bettors[msg.sender];
        require(bettor.balance >= _amount);
        require(decreaseBalance(bettor.account, _amount));
        require(msg.sender.send(_amount));
        return true;
    }

    function random(bytes32 _entropy) private view
    returns (bytes32) {
        bytes32 blockHash = blockhash(block.number - 1);
        bytes memory arguments = abi.encodePacked(block.difficulty, block.coinbase, now, blockHash, _entropy);
        return keccak256(arguments);
    }

    function randomRange(bytes32 _entropy, uint256 _max) private view
    returns (uint256) {
        uint256 rand;
        do {
            rand = uint256(random(_entropy));
        }
        while (rand >= (MAX_UINT256 - MAX_UINT256 % (_max + 1)));
        return rand %= (_max + 1);
    }

    function addBets() private
    returns (bool) {
        addBet(1, 35, "1");
        addBet(2, 35, "2");
        addBet(3, 35, "3");
        addBet(4, 35, "4");
        addBet(5, 35, "5");
        addBet(6, 35, "6");
        addBet(7, 35, "7");
        addBet(8, 35, "8");
        addBet(9, 35, "9");
        addBet(10, 35, "10");
        addBet(11, 35, "11");
        addBet(12, 35, "12");
        addBet(13, 35, "13");
        addBet(14, 35, "14");
        addBet(15, 35, "15");
        addBet(16, 35, "16");
        addBet(17, 35, "17");
        addBet(18, 35, "18");
        addBet(19, 35, "19");
        addBet(20, 35, "20");
        addBet(21, 35, "21");
        addBet(22, 35, "22");
        addBet(23, 35, "23");
        addBet(24, 35, "24");
        addBet(25, 35, "25");
        addBet(26, 35, "26");
        addBet(27, 35, "27");
        addBet(28, 35, "28");
        addBet(29, 35, "29");
        addBet(30, 35, "30");
        addBet(31, 35, "31");
        addBet(32, 35, "32");
        addBet(33, 35, "33");
        addBet(34, 35, "34");
        addBet(35, 35, "35");
        addBet(36, 35, "36");
        addBet(37, 35, "0");
        addBet(38, 35, "00");
        addBet(39, 1, "red");
        addBet(40, 1, "black");
        return true;
    }

    function addRules() private
    returns (bool) {
        addRule(1, 1, "1 straight");
        addRule(1, 39, "1 red");
        addRule(2, 2, "2 straight");
        addRule(2, 40, "2 black");
        addRule(3, 3, "3 straight");
        addRule(3, 39, "3 red");
        addRule(4, 4, "4 straight");
        addRule(4, 40, "4 black");
        addRule(5, 5, "5 straight");
        addRule(5, 39, "5 red");
        addRule(6, 6, "6 straight");
        addRule(6, 40, "6 black");
        addRule(7, 7, "7 straight");
        addRule(7, 39, "7 red");
        addRule(8, 8, "8 straight");
        addRule(8, 40, "8 black");
        addRule(9, 9, "9 straight");
        addRule(9, 39, "9 red");
        addRule(10, 10, "10 straight");
        addRule(10, 40, "10 black");
        addRule(11, 11, "11 straight");
        addRule(11, 39, "11 red");
        addRule(12, 12, "12 straight");
        addRule(12, 40, "12 black");
        addRule(13, 13, "13 straight");
        addRule(13, 39, "13 red");
        addRule(14, 14, "14 straight");
        addRule(14, 40, "14 black");
        addRule(15, 15, "15 straight");
        addRule(15, 39, "15 red");
        addRule(16, 16, "16 straight");
        addRule(16, 40, "16 black");
        addRule(17, 17, "17 straight");
        addRule(17, 39, "17 red");
        addRule(18, 18, "18 straight");
        addRule(18, 40, "18 black");
        addRule(19, 19, "19 straight");
        addRule(19, 39, "19 red");
        addRule(20, 20, "20 straight");
        addRule(20, 40, "20 black");
        addRule(21, 21, "21 straight");
        addRule(21, 39, "21 red");
        addRule(22, 22, "22 straight");
        addRule(22, 40, "22 black");
        addRule(23, 23, "23 straight");
        addRule(23, 39, "23 red");
        addRule(24, 24, "24 straight");
        addRule(24, 40, "24 black");
        addRule(25, 25, "25 straight");
        addRule(25, 39, "25 red");
        addRule(26, 26, "26 straight");
        addRule(26, 40, "26 black");
        addRule(27, 27, "27 straight");
        addRule(27, 39, "27 red");
        addRule(28, 28, "28 straight");
        addRule(28, 40, "28 black");
        addRule(29, 29, "29 straight");
        addRule(29, 39, "29 red");
        addRule(30, 30, "30 straight");
        addRule(30, 40, "30 black");
        addRule(31, 31, "31 straight");
        addRule(31, 39, "31 red");
        addRule(32, 32, "32 straight");
        addRule(32, 40, "32 black");
        addRule(33, 33, "33 straight");
        addRule(33, 39, "33 red");
        addRule(34, 34, "34 straight");
        addRule(34, 40, "34 black");
        addRule(35, 35, "35 straight");
        addRule(35, 39, "35 red");
        addRule(36, 36, "36 straight");
        addRule(36, 40, "36 black");
        addRule(37, 37, "0 straight");
        addRule(38, 38, "00 straight");
        return true;
    }

    function addWheelPockets() private
    returns (bool) {
        addWheelPocket(1);
        addWheelPocket(2);
        addWheelPocket(3);
        addWheelPocket(4);
        addWheelPocket(5);
        addWheelPocket(6);
        addWheelPocket(7);
        addWheelPocket(8);
        addWheelPocket(9);
        addWheelPocket(10);
        addWheelPocket(11);
        addWheelPocket(12);
        addWheelPocket(13);
        addWheelPocket(14);
        addWheelPocket(15);
        addWheelPocket(16);
        addWheelPocket(17);
        addWheelPocket(18);
        addWheelPocket(19);
        addWheelPocket(20);
        addWheelPocket(21);
        addWheelPocket(22);
        addWheelPocket(23);
        addWheelPocket(24);
        addWheelPocket(25);
        addWheelPocket(26);
        addWheelPocket(27);
        addWheelPocket(28);
        addWheelPocket(29);
        addWheelPocket(30);
        addWheelPocket(31);
        addWheelPocket(32);
        addWheelPocket(33);
        addWheelPocket(34);
        addWheelPocket(35);
        addWheelPocket(36);
        addWheelPocket(37);
        addWheelPocket(38);
        return true;
    }

    function decreaseBalance(address _account, uint256 _amount) private
    returns (bool) {
        if (_amount == 0) return true;
        totalBettorSupply -= _amount;
        Bettor storage bettor = bettors[_account];
        bettor.account = _account;
        bettor.balance -= _amount;
        if (bettor.balance == 0) {
            uint256 lastIndex = --bettorCount;
            if (bettor.index != lastIndex) {
                Bettor storage lastBettor = bettors[bettorAccounts[lastIndex]];
                lastBettor.index = bettor.index;
                bettorAccounts[bettor.index] = _account;
            }
            bettorAccounts[lastIndex] = address(0);
            bettors[_account] = Bettor(0, address(0), 0);
        }
        return true;
    }

    function increaseBalance(address _account, uint256 _amount) private
    returns (bool) {
        if (_amount == 0) return true;
        totalBettorSupply += _amount;
        Bettor storage bettor = bettors[_account];
        bettor.account = _account;
        bettor.balance += _amount;
        if (bettor.balance == _amount) {
            bettor.index = bettorCount++;
            bettorAccounts[bettor.index] = _account;
        }
        return true;
    }

    function processBet(uint8 _betID) private
    returns (bool) {
        Bet storage bet = bets[_betID];
        for (uint256 index = 0; index < bet.wagerCount; index ++) {
            Wager storage betWager = bet.wagers[index];
            if (bet.outcome[currentSpin_.winner] == true) {
                uint256 winnings = betWager.amount * bet.payout;
                uint256 payout = winnings + betWager.amount;
                require(increaseBalance(betWager.bettor, payout));
                currentSpin_.totalWon += winnings;
            }
            else {
                currentSpin_.totalLost += betWager.amount;
            }
            bet.wagers[index] = Wager(address(0), 0);
        }
        bet.wagerCount = 0;
        return true;
    }

    function processBets() private
    returns (bool) {
        for (uint8 betID = 0; betID <= totalUniqueBets; betID ++) {
            require(processBet(betID));
        }
        return true;
    }

    function processRevenue() private
    returns (bool) {
        if (currentSpin_.totalLost < currentSpin_.totalWon) {
            uint256 loss = currentSpin_.totalWon - currentSpin_.totalLost;
            require(Casino(casino).processLoss(loss));
        }
        if (currentSpin_.totalLost > currentSpin_.totalWon) {
            uint256 profit = currentSpin_.totalLost - currentSpin_.totalWon;
            require(Casino(casino).processProfit.value(profit)());
        }
        return true;
    }
}