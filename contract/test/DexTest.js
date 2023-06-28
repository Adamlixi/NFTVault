const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Dex", function () {
    let Exchange, OrderManagement, ERC721Mock, ERC20Mock, NFTRouter, WETH9;
    let exchange, orderManagement, erc721, erc20, nftRouter, weth9;
    let owner, maker, taker;

    beforeEach(async () => {
        [owner, maker, taker] = await ethers.getSigners();

        console.log("Contracts are deployed by:", owner.address);

        NFTRouter = await ethers.getContractFactory("NFTRouter");
        nftRouter = await NFTRouter.deploy();
        await nftRouter.deployed();
        console.log("nftRouter deployed at:", nftRouter.address);

        PoolFactory = await ethers.getContractFactory("NFTPoolFactory");
        poolFactory = await PoolFactory.deploy(owner.address, nftRouter.address);
        await poolFactory.deployed();
        console.log("PoolFactory deployed at:", poolFactory.address);
        await nftRouter.setFactory(poolFactory.address);

        OrderManagement = await ethers.getContractFactory("OrderManagement");
        orderManagement = await OrderManagement.deploy(nftRouter.address);
        await orderManagement.deployed();
        console.log("orderManagement deployed at:", orderManagement.address);

        WETH9 = await ethers.getContractFactory("WETH9");
        weth9 = await WETH9.deploy();
        await weth9.deployed();
        console.log("weth9 deployed at:", weth9.address);

        Exchange = await ethers.getContractFactory("Exchange");
        exchange = await Exchange.deploy(orderManagement.address, nftRouter.address, weth9.address);
        await exchange.deployed();
        console.log("exchange deployed at:", exchange.address);

        ERC20Mock = await ethers.getContractFactory("NFTVaultTest");
        erc20 = await ERC20Mock.deploy();
        await erc20.deployed();
        console.log("erc-20 token deployed at:", erc20.address);

        ERC721Mock = await ethers.getContractFactory("NFTVault");
        erc721 = await ERC721Mock.deploy();
        await erc721.deployed();
        console.log("erc-721 token deployed at:", erc721.address);

        NFTAuction = await ethers.getContractFactory("NFTAuction");
        nftAuction = await NFTAuction.deploy();
        await nftAuction.deployed();


    });

    it("should create and fill an order", async () => {
        const tokenDecimals = await erc20.decimals();
        const price = ethers.utils.parseUnits("1", tokenDecimals); // set price as 1 token

        // Mint an NFT for the owner
        const tokenId = 0;
        await erc721.connect(owner).safeMint(owner.address);


        await erc721.connect(owner).approve(maker.address, tokenId);

        // Transfer the NFT to maker
        await erc721.connect(owner).transferFrom(owner.address, maker.address, tokenId);
        // Now, maker has the tokenId 0

        // Maker approves OrderManagement to move the NFT
        // await erc721.connect(maker).approve(orderManagement.address, tokenId);
        await erc721.connect(maker).approve(exchange.address, tokenId);

        console.log("ERC721 owner is:", await erc721.ownerOf(tokenId));
        console.log("owner address is:", owner.address);
        console.log("maker address is:", maker.address);
        console.log("taker address is:", taker.address);

        // Sign order
        const expiration = Math.floor(Date.now() / 1000) + 3600; // expiration in 1 hour
        const message = ethers.utils.arrayify(ethers.utils.solidityKeccak256(
            ['address', 'address', 'uint256', 'uint256', 'uint256'],
            [erc721.address, erc20.address, tokenId, price, expiration]
        ));

        const signature = await maker.signMessage(message);

        // Create a pool for a mock erc20 token
        await poolFactory.createPool(erc20.address, nftAuction.address);
        const nftPool = await poolFactory.getPoolByToken(erc20.address);
        const Pool = await ethers.getContractFactory("NFTPool");
        const pool = await Pool.attach(nftPool);

        await nftRouter.connect(maker).registerNFT(erc721.address, tokenId, erc20.address);

        // Order maker call registerNFT
        // await nftRouter.connect(maker).registerNFT(erc721.address, tokenId, erc20.address);
        // Create order
        await orderManagement.connect(maker).createOrder(
            erc721.address,
            erc20.address,
            tokenId,
            price,
            expiration,
            signature
        );

        // Transfer ERC20 tokens from the initial owner to the taker
        const initialSupply = await erc20.balanceOf(owner.address);
        console.log("Initial ERC20 balance of owner:", initialSupply.toString());

        await erc20.connect(owner).transfer(taker.address, initialSupply);
        const balanceAfterTransfer = await erc20.balanceOf(taker.address);
        console.log("ERC20 balance of taker after transfer:", balanceAfterTransfer.toString());

        // Approve OrderManagement to spend tokens for the taker
        // await erc20.connect(taker).approve(orderManagement.address, price);
        await erc20.connect(taker).approve(exchange.address, price);

        // Fill order
        console.log("Filling order...");
        // await orderManagement.connect(taker).fillOrder(0);
        await exchange.connect(taker).fillOrder(0);

        const balanceAfterFillTaker = await erc20.balanceOf(taker.address);
        console.log("ERC20 balance of taker after filling order:", balanceAfterFillTaker.toString());

        const balanceAfterFillMaker = await erc20.balanceOf(maker.address);
        console.log("ERC20 balance of maker after filling order:", balanceAfterFillMaker.toString());

        const nftAccount = await pool.getNFTAccount(erc721.address, tokenId);
        console.log("NFT account balance: ", nftAccount.toString());

        // Verify that the taker now owns the NFT
        const newOwner = await erc721.ownerOf(tokenId);
        console.log("ERC721 owner after filling order:", newOwner);
        expect(newOwner).to.equal(taker.address);
    });



    // Start of the new test case
    it("should create and fill an order with Ether", async () => {
        // This block is the same
        const tokenId = 0;
        await erc721.connect(owner).safeMint(owner.address);

        await erc721.connect(owner).approve(maker.address, tokenId);

        await erc721.connect(owner).transferFrom(owner.address, maker.address, tokenId);

        await erc721.connect(maker).approve(exchange.address, tokenId);

        // Create a pool for weth9 token, which should abide to erc20
        await poolFactory.createPool(weth9.address, nftAuction.address);

        // This block is the same
        const expiration = Math.floor(Date.now() / 1000) + 3600;
        const message = ethers.utils.arrayify(ethers.utils.solidityKeccak256(
            ['address', 'address', 'uint256', 'uint256', 'uint256'],
            [erc721.address, weth9.address, tokenId, ethers.utils.parseEther("1"), expiration]
        ));

        const signature = await maker.signMessage(message);

        // Similar to previous test, but now we use weth as the token address to signify WEther
        await orderManagement.connect(maker).createOrder(
            erc721.address,
            weth9.address,
            tokenId,
            ethers.utils.parseEther("1"),
            expiration,
            signature
        );

        // Taker should have enough Ether. If not, consider transferring some Ether to taker here.

        // Instead of approving ERC20, the taker should directly call fillOrderWithEther and send the necessary amount of Ether
        await exchange.connect(taker).fillOrderWithEther(0, { value: ethers.utils.parseEther("1") });

        // Here, balance checks can be performed with respect to Ether rather than ERC20 tokens

        const balanceAfterFillMaker = await ethers.provider.getBalance(maker.address);
        console.log("Ether balance of maker after filling order:", ethers.utils.formatEther(balanceAfterFillMaker));

        // Here, the rest is the same
        const newOwner = await erc721.ownerOf(tokenId);
        console.log("ERC721 owner after filling order:", newOwner);
        expect(newOwner).to.equal(taker.address);
    });



});
