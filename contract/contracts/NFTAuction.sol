// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './interface/IERC20.sol';
import './interface/IERC721.sol';

contract NFTAuction {
    struct Auction {
        address seller;
        uint256 duration;
        uint256 startingPrice;
        uint256 highestBid;
        address highestBidder;
        bool active;
    }

    uint256 public constant DURATION = 3000; // ~9 hours in blocks (assuming ~15s/block)
    
    mapping(address => mapping(uint256 => Auction)) public auctions;

    // used to track admins allow to create auctions
    mapping(address => bool) public admins;

    event AuctionCreated(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 startingPrice);
    event AuctionBid(address indexed bidder, address indexed nftContract, uint256 indexed tokenId, uint256 amount);
    event AuctionEnded(address indexed winner, address indexed nftContract, uint256 indexed tokenId, uint256 amount);

    constructor() {
        // Make the deployer an admin
        admins[msg.sender] = true;
    }

    // Modifier that requires the caller to be an admin
    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can call this function");
        _;
    }

    // Function that allows an admin to add other admins
    function addAdmin(address admin) public onlyAdmin {
        admins[admin] = true;
    }

    // assumption: the auction contract owns the NFT
    function createAuction(address nftContract, uint256 tokenId, uint256 startingPrice) public onlyAdmin {
        require(IERC721(nftContract).ownerOf(tokenId) == address(this), "Auction contract does not own the NFT");
        require(!auctions[nftContract][tokenId].active, "Auction already active");

        auctions[nftContract][tokenId] = Auction({
            seller: msg.sender,
            duration: 0,
            startingPrice: startingPrice,
            highestBid: 0,
            highestBidder: address(0),
            active: true
        });

        emit AuctionCreated(msg.sender, nftContract, tokenId, startingPrice);
    }

    
    function placeBid(address nftContract, uint256 tokenId, address tokenContract, uint256 tokenAmount) public {
        require(auctions[nftContract][tokenId].active, "Auction not active");
        require(auctions[nftContract][tokenId].duration == 0 || block.number <= auctions[nftContract][tokenId].duration, "Auction ended");
        require(tokenAmount > auctions[nftContract][tokenId].highestBid, "There already is a higher bid");

        IERC20 token = IERC20(tokenContract);
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        if (auctions[nftContract][tokenId].highestBid != 0) {
            require(token.transfer(auctions[nftContract][tokenId].highestBidder, auctions[nftContract][tokenId].highestBid), "Refund of the previous bid failed");
        } else {
            auctions[nftContract][tokenId].duration = block.number + DURATION;
        }

        auctions[nftContract][tokenId].highestBid = tokenAmount;
        auctions[nftContract][tokenId].highestBidder = msg.sender;

        emit AuctionBid(msg.sender, nftContract, tokenId, tokenAmount);
    }


    function endAuction(address nftContract, uint256 tokenId) public {
        require(auctions[nftContract][tokenId].duration != 0 && block.number >= auctions[nftContract][tokenId].duration, "Auction not yet ended");
        require(auctions[nftContract][tokenId].active, "Auction already ended");

        auctions[nftContract][tokenId].active = false;
        //IERC721(nftContract).approve(address(this), tokenId);
        IERC721(nftContract).safeTransferFrom(address(this), auctions[nftContract][tokenId].highestBidder, tokenId);

        emit AuctionEnded(auctions[nftContract][tokenId].highestBidder, nftContract, tokenId, auctions[nftContract][tokenId].highestBid);
    }
}
