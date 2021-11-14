import { expect } from "chai";
import { deployContract, deployMockContract, MockProvider } from "ethereum-waffle";
import { BigNumber, Contract, ContractFactory, Signer } from "ethers";
import { ethers, deployments, network } from "hardhat";
import { MockSwapProvider__factory, MockSwapProvider, MintableErc20, MintableErc20__factory, TradingCore__factory, TradingCore } from "../typechain";
import { traceDeprecation } from "process";

const ether = ethers.utils.parseEther
const fether = ethers.utils.formatEther
const INFINITY = ether("999999999999999999")

describe("Margin-Trade Tests", () => {

    let signers : Signer[];
    let addresses : string[] = []; 
    let accounts: string[];

    beforeEach(async () => {
        signers = await ethers.getSigners();
        for(let i = 0 ; i < signers.length ; i++){
            addresses.push(await signers[i].getAddress())
        }
        accounts = addresses;
    })

    it("Test Simple Trade", async function() {
        console.log("Accounts[0]: " + accounts[0])

        let usdt = await deploy<MintableErc20__factory, MintableErc20>("MintableErc20", signers[0], ["USDT", "USDT"])
        let weth = await deploy<MintableErc20__factory, MintableErc20>("MintableErc20", signers[0], ["WETH", "WETH"])

        let swapProvider = await deploy<MockSwapProvider__factory, MockSwapProvider>("MockSwapProvider", signers[0])
        await swapProvider.setPrice(usdt.address, ether("1"))
        await swapProvider.setPrice(weth.address, ether("2000"));

        [usdt, weth].forEach(async _a => {
            let a = _a.connect(signers[0])
            await a.mint(ether("200000"))
            await a.transfer(swapProvider.address, ether("100000"))
        })

        await weth.connect(signers[0]).transfer(await signers[1].getAddress(), ether("100"))

        let trading = await deploy<TradingCore__factory, TradingCore>("TradingCore", signers[0], [swapProvider.address])
        let t1 = trading.connect(signers[0])
        await t1.addPool(usdt.address)
        await usdt.connect(signers[0]).approve(trading.address, INFINITY)
        await t1.supplyLiquidity(usdt.address, ether("50000"))

        let trade = trading.connect(signers[1])
        await weth.connect(signers[1]).approve(trade.address, INFINITY)
        await trade.addCollateral(weth.address, ether("10"))
        await trade.openTrade(weth.address, usdt.address, ether("5"), 3)

        await swapProvider.setPrice(weth.address, ether("2500"))

        let tid = await trade.userTrades(addresses[1], 0)
        await trade.closeTrade(tid)

        console.log(fether(await trade.collateral(addresses[1], weth.address)))
        console.log("Profit: " + fether((await trade.collateral(addresses[1], weth.address)).sub(ether("10"))) + "WETH")
        
    })

})

function it2(s: string, x: any){}

async function deploy<F extends ContractFactory, V extends Contract>(name: string, signer: Signer, args: any[] = []) : Promise<V>{
    const factory = ((await ethers.getContractFactory(name, signer)) as unknown) as F;
    let x = (await factory.deploy(...args)) as unknown as V;
    await x.deployed()
    return x
}