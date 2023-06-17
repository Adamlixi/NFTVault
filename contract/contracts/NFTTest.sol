// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTVault is ERC721, Ownable {
    using Counters for Counters.Counter;
    string[] nftInfo = ['{"name": "NFT #1","description": "My first NFT!", "image": "https://pic.quanjing.com/03/hn/QJ6244771088.jpg@!350h"}',
    '{"name": "NFT #11","description": "NFT!", "image": "https://pic.quanjing.com/gd/ef/QJ6709995743.jpg@!350h"}',
    '{"name": "NFT #111","description": "NFT!", "image": "https://pic.616pic.com/ys_bnew_img/00/55/44/9Mru8dUCfw.jpg"}',
    '{"name": "NFT #12","description": "NFT!", "image": "https://m.tuniucdn.com/filebroker/cdn/olb/54/a0/54a0e0a71c6c1f2fb40a1dfa738811dc_w320_h240_c1_t0.jpg"}',
    '{"name": "NFT #122","description": "NFT!", "image": "https://pic.quanjing.com/03/hn/QJ6244771088.jpg@!350h"}'];
    
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("NFTVault", "MTK") {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return nftInfo[tokenId % nftInfo.length];
    }
}