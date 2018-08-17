pragma solidity ^0.4.2;

import "./RouletteTable.sol";

contract Casino {

    struct Operator {
        uint256 index;
        address account;
        uint256 balance;
    }

    uint256 private operatorCount;

    address public creator;

    address public rouletteTable;

    bool public initialized;

    uint256 public totalOperatorSupply;

    mapping(address => Operator) public operators;

    mapping(uint256 => address) public operatorAccounts;

    modifier notRouletteTable() {
        require(msg.sender != rouletteTable);
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    modifier onlyIfInitialized() {
        require(initialized);
        _;
    }

    modifier onlyRouletteTable() {
        require(msg.sender == rouletteTable);
        _;
    }

    constructor() public {
        creator = msg.sender;
    }

    function() public payable
    notRouletteTable
    {
        require(increaseBalance(msg.sender, msg.value));
    }

    function operatorOf(address _account) public view
    returns (uint256 index, address account, uint256 balance) {
        Operator storage operator = operators[_account];
        return (operator.index, operator.account, operator.balance);
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

    function liquidate() public
    returns (bool) {
        Operator storage operator = operators[msg.sender];
        uint256 fundsToLiquidate = operator.balance;
        require(decreaseBalance(msg.sender, fundsToLiquidate));
        require(msg.sender.send(fundsToLiquidate));
        return true;
    }

    function processLoss(uint256 _amount) public
    onlyIfInitialized
    onlyRouletteTable
    returns (bool){
        for (uint256 index = 0; index < operatorCount; index++) {
            Operator storage operator = operators[operatorAccounts[index]];
            require(decreaseBalance(operator.account, _amount * (operator.balance / totalOperatorSupply)));
        }
        require(rouletteTable.send(_amount));
        return true;
    }

    function processProfit() payable public
    onlyIfInitialized
    onlyRouletteTable
    returns (bool){
        for (uint256 index = 0; index < operatorCount; index++) {
            Operator storage operator = operators[operatorAccounts[index]];
            require(increaseBalance(msg.sender, msg.value * (operator.balance / totalOperatorSupply)));
        }
        return true;
    }

    function withdraw(uint256 _amount) public
    returns (bool) {
        Operator storage operator = operators[msg.sender];
        require(operator.balance >= _amount);
        require(decreaseBalance(operator.account, _amount));
        require(msg.sender.send(_amount));
        return true;
    }

    function decreaseBalance(address _account, uint256 _amount) private
    returns (bool) {
        if (_amount == 0) return true;
        totalOperatorSupply -= _amount;
        Operator storage operator = operators[_account];
        operator.account = _account;
        operator.balance -= _amount;
        if (operator.balance == 0) {
            uint256 lastIndex = --operatorCount;
            if (operator.index != lastIndex) {
                Operator storage lastOperator = operators[operatorAccounts[lastIndex]];
                lastOperator.index = operator.index;
                operatorAccounts[operator.index] = _account;
            }
            operatorAccounts[lastIndex] = address(0);
            operators[_account] = Operator(0, address(0), 0);
        }
        return true;
    }

    function increaseBalance(address _account, uint256 _amount) private
    returns (bool) {
        if (_amount == 0) return true;
        totalOperatorSupply += _amount;
        Operator storage operator = operators[_account];
        operator.account = _account;
        operator.balance += _amount;
        if (operator.balance == _amount) {
            operator.index = operatorCount++;
            operatorAccounts[operator.index] = _account;
        }
        return true;
    }
}