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
    const bettorHarry = accounts[7];

    const creatorOptions = { from: creator };
    const dealerOptions = { from: dealer };

    var casino;
    var rouletteDealer;
    var rouletteTable;

    beforeEach('deploys and initializes contracts.', async () => {
        casino = await Casino.new(creatorOptions);
        rouletteTable = await RouletteTable.new(creatorOptions);

        await casino.sendTransaction({ from: operatorBob, value: 10000000 });
        await casino.initialize(rouletteTable.contract.address, creatorOptions);

        await rouletteTable.initializePockets(creatorOptions);
        await rouletteTable.initializeBets(creatorOptions);
        await rouletteTable.initializeRules(creatorOptions);
        await rouletteTable.initializeCasino(casino.contract.address, creatorOptions);
        await rouletteTable.initializeDealer(dealer, creatorOptions);

        assert.isTrue(await casino.initialized());
        assert.isTrue(await rouletteTable.initialized());
    });

    it('should decrement the bettor\'s balance after a bet is made', async () => {
        const balance = 250000;
        await rouletteTable.sendTransaction({ from: bettorAnnie, value: balance });

        await rouletteTable.openBetting(dealerOptions);
        await rouletteTable.wager(7, 10, { from: bettorAnnie });    // bet 10 on 7 straight
        await rouletteTable.closeBetting(dealerOptions);

        assert.equal(await rouletteTable.bettorOf(bettorAnnie).then(bettor => bettor[2].toNumber()), balance - 10);
    });

    it('should payout properly on single winning straight bet', async () => {
        const balance = 250000;
        await rouletteTable.sendTransaction({ from: bettorScott, value: balance });

        await rouletteTable.openBetting(dealerOptions);
        await rouletteTable.wager(36, 10, { from: bettorScott });    // bet 10 on 0 straight
        await rouletteTable.closeBetting(dealerOptions);
        await rouletteTable.markWinner(36, { from: dealer });        // winner 0

        assert.equal(await rouletteTable.bettorOf(bettorScott).then(bettor => bettor[2].toNumber()), balance + (10 * 35));
    });

    it('should not payout on single losing bet', async () => {
        const balance = 250000;
        await rouletteTable.sendTransaction({ from: bettorHarry, value: balance });

        await rouletteTable.openBetting(dealerOptions);
        await rouletteTable.wager(36, 10, { from: bettorHarry });   // bet 10 on 0 straight
        await rouletteTable.closeBetting(dealerOptions);
        await rouletteTable.markWinner(7, { from: dealer });        // winner 7 red

        assert.equal(await rouletteTable.bettorOf(bettorHarry).then(bettor => bettor[2].toNumber()), balance - 10);
    });

    it('should payout properly on multi-better scenario', async () => {
        const balance = 250000;

        await rouletteTable.sendTransaction({ from: bettorAnnie, value: balance });
        await rouletteTable.sendTransaction({ from: bettorScott, value: balance });
        await rouletteTable.sendTransaction({ from: operatorBob, value: balance });
        await rouletteTable.openBetting(dealerOptions);
        await rouletteTable.wager(7, 100, { from: bettorAnnie });   // bet 100 on 7 straight
        await rouletteTable.wager(22, 100, { from: bettorScott });  // bet 100 on 22 straight
        await rouletteTable.wager(40, 100, { from: operatorBob });  // bet 100 on black
        await rouletteTable.closeBetting(dealerOptions);
        await rouletteTable.markWinner(22, { from: dealer });       // winner 22 black

        assert.equal(await rouletteTable.bettorOf(bettorAnnie).then(bettor => bettor[2].toNumber()), balance - 100);
        assert.equal(await rouletteTable.bettorOf(bettorScott).then(bettor => bettor[2].toNumber()), balance - 100 + 3600);
        assert.equal(await rouletteTable.bettorOf(operatorBob).then(bettor => bettor[2].toNumber()), balance - 100 + 200);
    });

    it('should properly pull bets', async () => {
        const balance = 250000;

        await rouletteTable.sendTransaction({ from: bettorScott, value: balance });
        await rouletteTable.openBetting(dealerOptions);
        await rouletteTable.wager(40, 100, { from: bettorScott });  // bet 100 on black
        await rouletteTable.pullBets({ from: bettorScott });
        await rouletteTable.closeBetting(dealerOptions);
        await rouletteTable.markWinner(22, { from: dealer });       // winner 22 black

        assert.equal(await rouletteTable.bettorOf(bettorScott).then(bettor => bettor[2].toNumber()), balance);
    });

    it('should produce winning numbers between 0 and 39 when the wheel is spun', async () => {
        for (var i = 0; i < 10; i++) {
            const winner = await rouletteTable.spinWheel.call(43875876578456784365, { from: dealer }).then(x => x.toNumber());

            assert.isAbove(winner, 0);
            assert.isBelow(winner, 39);
        }
    });

    it('', async () => {

    });
});