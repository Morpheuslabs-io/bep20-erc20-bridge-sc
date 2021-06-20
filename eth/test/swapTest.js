/**
 * User swap token from ETH to BSC in 3 steps
 *  1) Approve for contract to get token out
 *  2) Swap token, send it to vault wallet
 *  3) Oracle listen to event and send token to user to the same address on BSC
 *   
 */

const ETHSwapAgentImpl = artifacts.require("ETHSwapAgentImpl");
const TestToken = artifacts.require("TestToken");

contract("Unit Testing for ETHSwapAgentImpl", accounts => {
    let owner = accounts[0];
    let vault = accounts[1];
    let swapper = accounts[2];
    
    beforeEach(async () => {
        // console.log(owner, vault, swapper);
        testToken = await TestToken.new({from: owner});
        ethSwapAgent = await ETHSwapAgentImpl.new(
            0,
            testToken.address, 
            owner, 
            vault,
            {from: owner}
        );

        await testToken.transfer(swapper, getBN(`${10**6}`, web3), {from: owner});
    });

    it('Swap token', async () => {
        console.log("Checking balance of user and vault before swap");
        let balanceVault = await testToken.balanceOf(vault);
        let balanceUser = await testToken.balanceOf(swapper);
        let amount = getRandomInt(0, 1000);

        console.log(`Balance of user ${balanceUser}, balance of vault ${balanceVault}`);
        console.log(`Swap ${amount} of token`);
        
        await testToken.approve(ethSwapAgent.address, getBN(`${amount}`, web3), {from: swapper});
        await ethSwapAgent.swapETH2BSC(amount, {from: swapper});

        balanceVault = await testToken.balanceOf(vault);
        balanceUser = await testToken.balanceOf(swapper);

        console.log(`New user balance ${balanceUser}, new vault balance ${balanceVault}`);

        assert.equal(balanceVault.toString(), amount, "Balance vault is correct");
    });

    it('Send tokens to user list', async () => {
        let batch = [];

        for(let i = 0 ; i < 10; i++) {
            let amount = getRandomInt(0, 1000);
            let { address, privateKey } = await web3.eth.accounts.create();
            await testToken.approve(ethSwapAgent.address, getBN(`${amount}`, web3), {from: swapper});
            let txHash = await ethSwapAgent.swapETH2BSC(getBN(`${amount}`, web3), {from: swapper});
            // console.log(txHash);

            batch.push({txHash: txHash.tx, amount, receiver: address});
        }

        let ownerBalance = await testToken.balanceOf(owner);
        await testToken.approve(ethSwapAgent.address, ownerBalance, {from: owner});

        await ethSwapAgent.fillBSC2ETHSwap(
            batch.map(tx => tx.txHash),
            batch.map(tx => tx.receiver), 
            batch.map(tx => getBN(`${tx.amount}`, web3).toString()), 
            {from: owner}
        );

        assert(true);
    });
});


function getBN(number, web3) {
    const BigNumber = web3.utils.BN;
    return new BigNumber(`${web3.utils.toWei(number, "ether")}`);
}

function getRandomInt(min, max) {
	return Math.floor(Math.random() * (max - min + 1) + min);
}

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
