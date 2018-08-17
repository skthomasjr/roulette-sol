module.exports = {
    networks: {
        [process.env.NETWORK_NAME]: {
            network_id: process.env.NETWORK_CHAIN_ID,
            host: process.env.NETWORK_HOST,
            port: process.env.NETWORK_PORT,
            gas: 6000000
        }
    }
};