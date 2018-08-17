const Casino = artifacts.require("Casino");
const RouletteDealer = artifacts.require("RouletteDealer");
const RouletteTable = artifacts.require("RouletteTable");

contract('RouletteTable', async (accounts) => {
    const creator = accounts[0];
    const dealer = accounts[1];
    const bettorAnnie = accounts[2];
    const bettorScott = accounts[3];
    const operatorBob = accounts[4];
    const operatorJan = accounts[5];
    const hackerDoyle = accounts[6];

    var casino;
    var rouletteDealer;
    var rouletteTable;

    beforeEach('deploys and initializes contracts.', async () => {
        const creatorOptions = { from: creator };
        casino = await Casino.new(creatorOptions);
        rouletteDealer = await RouletteDealer.new(creatorOptions);
        rouletteTable = await RouletteTable.new(creatorOptions);

        await casino.initialize(rouletteTable.contract.address, creatorOptions);
        await rouletteTable.initializePockets(creatorOptions);
        await rouletteTable.initializeBets(creatorOptions);
        await rouletteTable.initializeRules(creatorOptions);
        await rouletteTable.initializeCasino(casino.contract.address, creatorOptions);
        await rouletteTable.initializeDealer(rouletteDealer.contract.address, creatorOptions);

        assert.isTrue(await casino.initialized());
        assert.isTrue(await rouletteTable.initialized());
    });

    it('should properly allocate funds sent to the contract', async () => {
        const amountToSend = 1000;

        const currentBalance = await rouletteTable.bettorOf(bettorAnnie).then(bettor => bettor[2].toNumber());
        const expectedBalance = amountToSend + currentBalance;
        await rouletteTable.sendTransaction({ from: bettorAnnie, value: amountToSend });

        assert.equal(expectedBalance, await rouletteTable.bettorOf(bettorAnnie).then(bettor => bettor[2].toNumber()));
    });

    it('should properly allocate funds sent to the contract if a single wei is sent', async () => {
        const amountToSend = 1;

        const currentBalance = await rouletteTable.bettorOf(bettorAnnie).then(bettor => bettor[2].toNumber());
        const expectedBalance = amountToSend + currentBalance;
        await rouletteTable.sendTransaction({ from: bettorAnnie, value: amountToSend });

        assert.equal(expectedBalance, await rouletteTable.bettorOf(bettorAnnie).then(bettor => bettor[2].toNumber()));
    });
});
