const KYCContract = artifacts.require("KYC");

module.exports = function(deployer) {
  deployer.deploy(KYCContract);
};
