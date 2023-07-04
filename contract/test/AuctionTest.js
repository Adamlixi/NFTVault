const { expect } = require("chai");

describe("NFTAuction Test", function () {
    let NFTAuction, mockERC20, mockERC721;
    let nftAuction, pool, erc20, erc721;
    let owner, bidder, bidder2;

    beforeEach(async () => {
        [owner, bidder, bidder2] = await ethers.getSigners();

        mockERC20 = await ethers.getContractFactory("NFTVaultTest");
        erc20 = await mockERC20.deploy();
        await erc20.deployed();

        mockERC721 = await ethers.getContractFactory("NFTVault");
        erc721 = await mockERC721.deploy();
        await erc721.deployed();

        NFTRouter = await ethers.getContractFactory("NFTRouter");
        nftRouter = await NFTRouter.deploy();
        await nftRouter.deployed();
        console.log("nftRouter deployed at:", nftRouter.address);

        PoolFactory = await ethers.getContractFactory("NFTPoolFactory");
        poolFactory = await PoolFactory.deploy(owner.address, nftRouter.address);
        await poolFactory.deployed();
        console.log("PoolFactory deployed at:", poolFactory.address);
        await nftRouter.setFactory(poolFactory.address);

        NFTAuction = await ethers.getContractFactory("NFTAuction");
        nftAuction = await NFTAuction.deploy();
        await nftAuction.deployed();

        // Create a pool for a mock erc20 token
        await poolFactory.createPool(erc20.address, nftAuction.address);
        const nftPool = await poolFactory.getPoolByToken(erc20.address);
        const Pool = await ethers.getContractFactory("NFTPool");
        pool = await Pool.attach(nftPool);

    });

    it("Auction Creation and Bid Test", async function () {
        const tokenId = 0;
        await erc721.connect(owner).safeMint(owner.address);

        await erc721.connect(owner).approve(nftAuction.address, tokenId);

        await erc721.connect(owner).transferFrom(owner.address, nftAuction.address, tokenId);

        await nftAuction.connect(owner).createAuction(erc721.address, tokenId, 100);

        expect((await nftAuction.auctions(erc721.address, tokenId)).active).to.equal(true);

        await erc20.connect(bidder).approve(nftAuction.address, 200);
        await erc20.connect(owner).transfer(bidder.address, 500); // Transfer 500 tokens to bidder
        await erc20.connect(bidder).approve(nftAuction.address, 200); // Approve NFT Auction contract to spend 200 tokens
        await nftAuction.connect(bidder).placeBid(erc721.address, tokenId, erc20.address, 200); // Bid 200 tokens
        

        expect((await nftAuction.auctions(erc721.address, tokenId)).highestBid).to.equal(200);
        expect((await nftAuction.auctions(erc721.address, tokenId)).highestBidder).to.equal(bidder.address);
    });
    it("Outbidding Test", async function () {
        const tokenId = 0;
        await erc721.connect(owner).safeMint(owner.address);
    
        await erc721.connect(owner).approve(nftAuction.address, tokenId);
    
        await erc721.connect(owner).transferFrom(owner.address, nftAuction.address, tokenId);
    
        await nftAuction.connect(owner).createAuction(erc721.address, tokenId, 100);
    
        await erc20.connect(bidder).approve(nftAuction.address, 200);
        await erc20.connect(owner).transfer(bidder.address, 500);
        await nftAuction.connect(bidder).placeBid(erc721.address, tokenId, erc20.address, 200);
    
        // New bid from bidder2
        await erc20.connect(bidder2).approve(nftAuction.address, 300);
        await erc20.connect(owner).transfer(bidder2.address, 600);
        await nftAuction.connect(bidder2).placeBid(erc721.address, tokenId, erc20.address, 300);
    
        expect((await nftAuction.auctions(erc721.address, tokenId)).highestBid).to.equal(300);
        expect((await nftAuction.auctions(erc721.address, tokenId)).highestBidder).to.equal(bidder2.address);
    });
    
    it("End Auction Test", async function () {
        const tokenId = 0;
        await erc721.connect(owner).safeMint(owner.address);
    
        await erc721.connect(owner).approve(nftAuction.address, tokenId);
    
        await erc721.connect(owner).transferFrom(owner.address, nftAuction.address, tokenId);
    
        await nftAuction.connect(owner).createAuction(erc721.address, tokenId, 100);
    
        await erc20.connect(bidder).approve(nftAuction.address, 200);
        await erc20.connect(owner).transfer(bidder.address, 500);
        await nftAuction.connect(bidder).placeBid(erc721.address, tokenId, erc20.address, 200);
    
        // Simulate passage of time until auction duration, which is 24000 blocks (roughly 3 days)
        for(let i = 0; i < 3000; i++){
            await ethers.provider.send("evm_mine");
        }

    
        await nftAuction.connect(bidder).endAuction(erc721.address, tokenId);
    
        expect((await nftAuction.auctions(erc721.address, tokenId)).active).to.equal(false);
    });
    

});

