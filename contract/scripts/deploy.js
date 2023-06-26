const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    // const Token = await ethers.getContractFactory("Token");
    // const token = await Token.deploy();

    // NFTVault Test Coin
    const Tokens = await ethers.getContractFactory("NFTVaultTest");
    const token = await Tokens.deploy();
    await token.deployed();
    console.log("NFTVaultTest Token address:", token.address);

    const NFTRouter = await ethers.getContractFactory("NFTRouter");
    const nftRouter = await NFTRouter.deploy();
    await nftRouter.deployed();
    console.log("NFTRouter address:", nftRouter.address);

    const PoolFactory = await ethers.getContractFactory("NFTPoolFactory");
    const poolFactory = await PoolFactory.deploy(deployer.address, nftRouter.address);
    await poolFactory.deployed();
    console.log("NFTPoolFactory address:", poolFactory.address);

    await poolFactory.createPool(token.address);
    const createPool =  await poolFactory.getPoolByToken(token.address);
    console.log("NFTPoolFactory createPool:", createPool);

    const WETH = await ethers.getContractFactory("WETH9");
    const weth = await WETH.deploy();
    await weth.deployed();
    console.log("WETH address:", weth.address);

    OrderManagement = await ethers.getContractFactory("OrderManagement");
    orderManagement = await OrderManagement.deploy(nftRouter.address);
    await orderManagement.deployed();
    console.log("OrderManagement address:", orderManagement.address);

    Exchange = await ethers.getContractFactory("Exchange");
    exchange = await Exchange.deploy(orderManagement.address, nftRouter.address, weth.address);
    await exchange.deployed();
    console.log("Exchange address:", exchange.address);

    NFTAuction = await ethers.getContractFactory("NFTAuction");
    nftAuction = await NFTAuction.deploy();
    await nftAuction.deployed();
    console.log("NFTAuction address:", nftAuction.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });