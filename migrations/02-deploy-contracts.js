const Casino = artifacts.require("./Casino.sol");
const RouletteDealer = artifacts.require("./RouletteDealer.sol");
const RouletteTable = artifacts.require("./RouletteTable.sol");

module.exports = async (deployer, network, accounts) => {
    const creator = accounts[0];
    deployer.deploy(Casino, { from: creator });
    deployer.deploy(RouletteDealer, { from: creator });
    deployer.deploy(RouletteTable, { from: creator });
};