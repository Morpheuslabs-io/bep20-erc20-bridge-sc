
const ETHBSCSwap = artifacts.require('ETHBSCSwap');

module.exports = function (deployer) {
  const fee = 0;
  const tokenAddress = "0x73B09649DBf09FDc6bBdBe2679aBd745e0f5771b";
  const ownerAddress = "0x34d8c42c5c2D6aDE62332a2760805D44Db5d3EE3";
  const vaultAddress = "0x34d8c42c5c2D6aDE62332a2760805D44Db5d3EE3";

  deployer.deploy(ETHBSCSwap, fee, tokenAddress, ownerAddress, vaultAddress);
};
