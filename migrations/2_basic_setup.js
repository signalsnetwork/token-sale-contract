var Multisig = artifacts.require("./MultiSigWallet.sol");
var Token = artifacts.require("./SignalsToken.sol");
var Register = artifacts.require("./KYC.sol");
var Pools = artifacts.require("./KYC.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(Multisig);
  deployer.deploy(Token);
  deployer.deploy(Register)
  deployer.deploy(
              Pools,
              Token,
              Multisig,
              Register,
              1,
              2);
};
