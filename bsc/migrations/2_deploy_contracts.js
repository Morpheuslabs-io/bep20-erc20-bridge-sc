const MITx = artifacts.require('MITx');
const BSCETHSwap = artifacts.require('BSCETHSwap');

module.exports = function (deployer) {
  const bscSwapFee = 0;
  const ethSwapInitTxHash = '0x718223eeeece3b0a575038304a53ceec7a5b1f8e8510eef81f085264ede0c138';
  const erc20Addr = '0x73B09649DBf09FDc6bBdBe2679aBd745e0f5771b';
  const ownerAddr = '0x34d8c42c5c2D6aDE62332a2760805D44Db5d3EE3';
  const hotWalletAddress = '0x34d8c42c5c2D6aDE62332a2760805D44Db5d3EE3';

  let tokenContract;
  let swapContract;

  deployer.deploy(MITx)
    .then(instance => {
      tokenContract = instance;
      // deploy swap contract
      return deployer.deploy(BSCETHSwap, bscSwapFee, ethSwapInitTxHash, erc20Addr, instance.address)
    })
    .then(instance => {
      swapContract = instance;
      // transferOwner of token to swap for mint
      return tokenContract.transferOwnership(instance.address);
    })
    .then(txHash => {
      //console.log(txHash);
      // add hotwallet
      return swapContract.addWhitelist(hotWalletAddress);
    })
    .then(txHash => {
      return swapContract.transferOwnership(ownerAddr);
    })
    .then(txHash => {
      // console.log(txHash);
    });
};
