// const TronWeb = require('tronweb');
/*
     Create a .env file (it must be gitignored) containing something like

       export PRIVATE_KEY_MAINNET=4E7FECCB71207B867C495B51A9758B104B1D4422088A87F4978BE64636656243

     Then, run the migration with:

       source .env && tronbox migrate --network mainnet

     */

const PRIVATE_KEY_MAINNET= '4E7FECCB71207B867C495B51A9758B104B1D4422088A87F4978BE64636656243';
const PRIVATE_KEY_SHASTA= '224fdc21315cbb2bfd2e1eaa0336dc9ea41ee62cd86da8dae8d7763857ec201d';

var TronWeb = require('tronweb');

// import {Client} from "@tronscan/client";
// const CryptoUtils = require("@tronscan/client/src/utils/crypto");
// const client = new Client();
// client.getContractTxs({
//
// })
// let recentBlocks = await client.getBlocks({
//   sort: '-number',
//   limit: 10,
// });



// var tronWeb = new TronWeb(
//     "http://127.0.0.1:9090",
//   "http://127.0.0.1:9090",
//   "http://127.0.0.1:9090",
//     '287848c23c18f2b837b78632b85884eff3d42ad79fa9e16481ec153b77dea7a1'
// );
var tronWeb = new TronWeb({
  privateKey: PRIVATE_KEY_SHASTA,
  fullHost: 'https://api.shasta.trongrid.io',
});

var port = process.env.HOST_PORT || 9090;

module.exports = {
  networks: {
    mainnet: {
      privateKey: process.env.PRIVATE_KEY_MAINNET,

      userFeePercentage: 100,
      feeLimit: 1e8,
      fullHost: 'https://api.trongrid.io',
      network_id: '1'
    },
    shasta: {
      privateKey: PRIVATE_KEY_SHASTA, //process.env.PRIVATE_KEY_SHASTA,
      userFeePercentage: 30,
      feeLimit: 1e8,
      fullHost: 'https://api.shasta.trongrid.io',
      network_id: '*'
    },
    nile: {
      privateKey: process.env.PRIVATE_KEY_NILE,
      fullNode: 'https://httpapi.nileex.io/wallet',
      solidityNode: 'https://httpapi.nileex.io/walletsolidity',
      eventServer: 'https://eventtest.nileex.io',
      network_id: '3'
    },
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
