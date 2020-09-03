var SmartLotto = artifacts.require("SmartLotto");
var CareerPlan = artifacts.require("CareerPlan");
var Lotto = artifacts.require("Lotto");

module.exports = async (deployer) => {
  await deployer.deploy(CareerPlan);
  await deployer.link(CareerPlan, SmartLotto);
  await deployer.deploy(Lotto);
  await deployer.link(Lotto, SmartLotto);
  await deployer.deploy(SmartLotto, 'THVVRTVpqt6Ek3Bo4ZRuEpeiUhssHEdmtG', CareerPlan.address, Lotto.address, 'TNMPJKCaebuAoaVm7aWCVGwAdGediZYCrg');
  const CareerPlanContract = await CareerPlan.deployed();
  await CareerPlanContract.setSmartLottoAddress(SmartLotto.address);
  const LottoContract = await Lotto.deployed();
  await LottoContract.setSmartLottoAddress(SmartLotto.address);
};
