const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Dex", function () {
    let OrderManagement, ERC721Mock, ERC20Mock, NFTRouter;
    let orderManagement, erc721, erc20, nftRouter;
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

        ERC20Mock = await ethers.getContractFactory("NFTVaultTest");
        erc20 = await ERC20Mock.deploy();
        await erc20.deployed();
        console.log("erc-20 token deployed at:", erc20.address);

        ERC721Mock = await ethers.getContractFactory("NFTVault");
        erc721 = await ERC721Mock.deploy();
        await erc721.deployed();
        console.log("erc-721 token deployed at:", erc721.address);
        
    });

    it("should create and fill an order", async () => {
        const tokenDecimals = await erc20.decimals();
        const price = ethers.utils.parseUnits("1", tokenDecimals); // set price as 1 token
        
        // Mint an NFT for the owner
        const tokenId = 0;
        await erc721.connect(owner).safeMint(owner.address);

        // Transfer the NFT to maker
        await erc721.connect(owner).transferFrom(owner.address, maker.address, tokenId);
        // Now, maker has the tokenId 0

        // Maker approves OrderManagement to move the NFT
        await erc721.connect(maker).approve(orderManagement.address, tokenId);

        // Sign order
        const expiration = Math.floor(Date.now() / 1000) + 3600; // expiration in 1 hour
        const message = ethers.utils.arrayify(ethers.utils.solidityKeccak256(
            ['address', 'address', 'uint256', 'uint256', 'uint256'],
            [erc721.address, erc20.address, tokenId, price, expiration]
        ));
        
        const signature = await maker.signMessage(message);

        // Create a pool for erc20 token
        await poolFactory.createPool(erc20.address);

        // Order maker call registerNFT
        await nftRouter.connect(maker).registerNFT(erc721.address, tokenId, erc20.address);
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
        await erc20.connect(taker).approve(orderManagement.address, price);

        // Fill order
        console.log("Filling order...");
        await orderManagement.connect(taker).fillOrder(0);

        const balanceAfterFill = await erc20.balanceOf(taker.address);
        console.log("ERC20 balance of taker after filling order:", balanceAfterFill.toString());


        // Verify that the taker now owns the NFT
        const newOwner = await erc721.ownerOf(tokenId);
        console.log("ERC721 owner after filling order:", newOwner);
        expect(newOwner).to.equal(taker.address);
    });
});
