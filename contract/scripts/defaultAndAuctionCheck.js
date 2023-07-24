const ethers = require('ethers');

const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545'); // replace with node url
const wallet = new ethers.Wallet('your private key', provider); // Replace with wallet private key
const nftPoolContractAddress = '0x...'; // Replace with the NFTPool contract address
const nftAuctionContractAddress = '0x...'; // Replace with the NFTAuction contract address

const fs = require('fs');
const nftPoolJson = JSON.parse(fs.readFileSync('artifacts/contracts/NFTPool.sol/NFTPool.json', 'utf8'));
const nftPoolABI  = nftPoolJson.abi;
const nftAuctionJson = JSON.parse(fs.readFileSync('artifacts/contracts/NFTAuction.sol/NFTAuction.json', 'utf8'));
const nftAuctionABI  = nftAuctionJson.abi;

const nftPoolContract = new ethers.Contract(nftPoolContractAddress, nftPoolABI, wallet);
const nftAuctionContract = new ethers.Contract(nftAuctionContractAddress, nftAuctionABI, wallet);

// Assume a list of all NFT addresses and their token IDs, need to fill in address of NFTTest
// temporary solution, need to be replaced with a database
const nftList = [
  { nftAddress: '0x...', tokenId: '11' }, // Replace with NFT address
  { nftAddress: '0x...', tokenId: '111' },
  { nftAddress: '0x...', tokenId: '12' },
  { nftAddress: '0x...', tokenId: '122' },
];

async function checkNFTs() {
  for (const nft of nftList) {
    const state = await nftPoolContract.checkNFTStatus(nft.nftAddress, nft.tokenId);

    if (state < Math.floor(Date.now() / 1000)) {
      const tx = await nftPoolContract.defaultAndStartAuction(nft.nftAddress, nft.tokenId);
      await tx.wait();
      console.log(`Started auction for NFT ${nft.nftAddress} ${nft.tokenId}`);
    }
  }
}

async function checkAuctions() {
  for (const nft of nftList) {
    const auction = await nftAuctionContract.auctions(nft.nftAddress, nft.tokenId);

    if (auction.active && auction.duration !== 0 && auction.duration <= Math.floor(Date.now() / 1000)) {
      const tx = await nftAuctionContract.endAuction(nft.nftAddress, nft.tokenId);
      await tx.wait();
      console.log(`Ended auction for NFT ${nft.nftAddress} ${nft.tokenId}`);
    }
  }
}

// Run the checks every 10 minutes
setInterval(async () => {
  await checkNFTs();
  await checkAuctions();
}, 10 * 60 * 1000);
