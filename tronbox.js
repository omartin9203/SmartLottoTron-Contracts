// const TronWeb = require('tronweb');

var TronWeb = require('tronweb');

var tronWeb = new TronWeb(
    "http://127.0.0.1:9090",
    "http://127.0.0.1:9090",
    "http://127.0.0.1:9090",
    '287848c23c18f2b837b78632b85884eff3d42ad79fa9e16481ec153b77dea7a1'
);

var port = process.env.HOST_PORT || 9090;


// const tronWeb = new TronWeb({
//   fullHost: 'http://127.0.0.1:' + port,
//   privateKey: '287848c23c18f2b837b78632b85884eff3d42ad79fa9e16481ec153b77dea7a1',
// })

module.exports = {
  networks: {
    // mainnet: {
    //   // Don't put your private key here:
    //   privateKey: '4E7FECCB71207B867C495B51A9758B104B1D4422088A87F4978BE64636656243', //process.env.PRIVATE_KEY_MAINNET,
    //   /*
    //   Create a .env file (it must be gitignored) containing something like

    //     export PRIVATE_KEY_MAINNET=4E7FECCB71207B867C495B51A9758B104B1D4422088A87F4978BE64636656243

    //   Then, run the migration with:

    //     source .env && tronbox migrate --network mainnet

    //   */
    //   userFeePercentage: 100,
    //   feeLimit: 1e8,
    //   fullHost: 'https://api.trongrid.io',
    //   network_id: '1'
    // },
    // shasta: {
    //   privateKey: process.env.PRIVATE_KEY_SHASTA,
    //   userFeePercentage: 30,
    //   feeLimit: 1e8,
    //   fullHost: 'https://api.shasta.trongrid.io',
    //   network_id: '*'
    // },
    // nile: {
    //   privateKey: process.env.PRIVATE_KEY_NILE,
    //   fullNode: 'https://httpapi.nileex.io/wallet',
    //   solidityNode: 'https://httpapi.nileex.io/walletsolidity',
    //   eventServer: 'https://eventtest.nileex.io',
    //   network_id: '3'
    // },
    development: {
      // // For trontools/quickstart docker image
      // privateKey: 'da146374a75310b9666e834ee4ad0866d6f4035967bfc76217c5a495fff9f0d0',
      // userFeePercentage: 50,
      // feeLimit: 1000000,
      // fullnode: 'http://127.0.0.1:' + port,
      // // solidityNode: "http://127.0.0.1:" + port,
      // // eventServer: "http://127.0.0.1:" + port,
      // originEnergyLimit: 10000000,
      // consume_user_resource_percent: 30,
      // network_id: "*",
      privateKey: 'da146374a75310b9666e834ee4ad0866d6f4035967bfc76217c5a495fff9f0d0',
      fullHost: "http://127.0.0.1:9090",
      network_id: "9"
    },
    compilers: {
      solc: {
        version: '0.5.10'
      }
    }
  }
}
