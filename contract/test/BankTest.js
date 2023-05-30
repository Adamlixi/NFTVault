const { expect } = require("chai");

describe("Bank Test", function () {
  it("Bank core code test.Part1", async function () {
    const [owner] = await ethers.getSigners();

    // const Token = await ethers.getContractFactory("Token");

    // const hardhatToken = await Token.deploy();

    // const ownerBalance = await hardhatToken.balanceOf(owner.address);
    // expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);

    const Tokens = await ethers.getContractFactory("NFTVaultTest");
    const token = await Tokens.deploy();
    await token.deployed();
    console.log("NFTVaultTest Token address:", token.address);

    const NFTRouter = await ethers.getContractFactory("NFTRouter");
    const nftRouter = await NFTRouter.deploy();
    await nftRouter.deployed();
    console.log("NFTRouter address:", nftRouter.address);

    const PoolFactory = await ethers.getContractFactory("NFTPoolFactory");
    const poolFactory = await PoolFactory.deploy(owner.address, nftRouter.address);
    await poolFactory.deployed();
    console.log("NFTPoolFactory address:", poolFactory.address);

    await nftRouter.setFactory(poolFactory.address);
    console.log("NFTRouter setPoolFactory:", poolFactory.address);

    const NFTTest = await ethers.getContractFactory("NFTVault");
    const nftTest = await NFTTest.deploy();
    await nftTest.deployed();
    console.log("NFTTest address:", nftTest.address);

    await nftTest.safeMint(owner.address)
    console.log("NFTMint to address:", owner.address);

    await poolFactory.createPool(token.address);
    const nftPool =  await poolFactory.getPoolByToken(token.address);
    console.log("NFTPoolFactory createPool:", nftPool);


    expect(await nftTest.ownerOf(0)).to.equal(owner.address);
    console.log("NFT ownerOf:", await nftTest.ownerOf(0));

    await nftRouter.registerNFT(nftTest.address, 0, token.address);
    console.log("NFTRouter registerNFT:", nftTest.address, 0, token.address);

    console.log(await nftRouter.getNFTAddress(await nftTest.address, 0));
    
    await token.approve(nftRouter.address, 2000)
    await nftRouter.transferIntoNFT(nftTest.address, 0, 2000);
    console.log("NFTRouter transferIntoNFT:", nftTest.address, 0, 2000);

    const Pool = await ethers.getContractFactory("NFTPool");
    const pool = await Pool.attach(nftPool);
    expect(await pool.getNFTAccount(nftTest.address, 0)).to.equal(2000);

    console.log("NFTPool address:", pool.address);
    await nftTest.approve(nftRouter.address, 0);
    console.log("NFTPool Approved");
    console.log("Balance of Pool:", await pool.getTotalSupply());
    await nftRouter.mortgageNFT(nftTest.address, 0, 2000, 233333333333);
    console.log("mortgageNFTed");
    expect(await nftTest.ownerOf(0)).to.equal(pool.address);
    console.log("Balance of Token:", await token.balanceOf(owner.address));

    await token.approve(nftRouter.address, 2000);
    await nftRouter.redeemNFT(nftTest.address, 0, 2000);
    expect(await pool.getNFTAccount(nftTest.address, 0)).to.equal(2000);
    expect(await nftTest.ownerOf(0)).to.equal(owner.address);
  });
});