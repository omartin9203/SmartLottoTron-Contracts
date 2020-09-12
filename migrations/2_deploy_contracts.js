var SmartLotto = artifacts.require("SmartLotto");
var CareerPlan = artifacts.require("CareerPlan");
var Lotto = artifacts.require("Lotto");
var TronWeb = require('tronweb');
var tronWeb = new TronWeb({
  fullHost: 'https://api.shasta.trongrid.io',
});

module.exports = async (deployer) => {
  await deployer.deploy(CareerPlan);
  await deployer.link(CareerPlan, SmartLotto);
  await deployer.deploy(Lotto);
  await deployer.link(Lotto, SmartLotto);
  await deployer.deploy(SmartLotto, 'TTSqi5jVfh2N6x9Voi4PsQiYUjUgRvQkhs', CareerPlan.address, Lotto.address, 'TEtK2n8SP7it7J3KeU7dFHZcAjGrSz3o3c');
  const CareerPlanContract = await CareerPlan.deployed();
  const smartLottoAddress = await tronWeb.address.fromHex(SmartLotto.address);
  console.log('address smart lotto{+++++}', smartLottoAddress)
  await CareerPlanContract.call('setSmartLottoAddress', [smartLottoAddress]);
  // await CareerPlanContract.setSmartLottoAddress(smartLottoAddress);
  const LottoContract = await Lotto.deployed();
  await LottoContract.call('setSmartLottoAddress', [smartLottoAddress]);
  // await LottoContract.setSmartLottoAddress(smartLottoAddress);
};
