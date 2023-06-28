// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './interface/INFTRouter.sol';
import './interface/IERC20.sol';
import './interface/INFTPool.sol';
import './interface/IERC721.sol';
import './interface/INFTPoolFactory.sol';
import './libraries/TransferHelper.sol';
import "hardhat/console.sol";

contract NFTRouter is INFTRouter {
    address public factory; //工厂地址
    address public owner;
    event PoolMortgage(address indexed sender, address tokenPool);
    mapping(address => mapping (uint256 => address)) public nftAddress;

    constructor() {
        //factory地址为合约布署者
        owner = msg.sender;
    }

    receive() external payable {} // to support receiving ETH by default
    fallback() external payable {}
    
    function setFactory(address _factory) external {
        require(msg.sender == owner, "NFTRouter: NOT_OWNER");
        factory = _factory;
    }

    function registerNFT(address nft, uint256 tokenId, address token) external override {
        address tokenPool = INFTPoolFactory(factory).getPoolByToken(token);
        require(tokenPool != address(0), "NFTRouter: NOT_REGISTER_POOL");

        if (nftAddress[nft][tokenId] == address(0)) {
            INFTPool(tokenPool).registerNFT(nft, tokenId);
            nftAddress[nft][tokenId] = tokenPool;
        }
    }

    function transferIntoNFT(address nft, uint256 tokenId, uint256 account) external override {
        address tokenPool = nftAddress[nft][tokenId];
        require(tokenPool != address(0), "NFTRouter: NFT_POOL_NOT_CREATED");
        // require(IERC721(nft).ownerOf(tokenId) == msg.sender, "NFTRouter: NOT_OWNER");
        address token = INFTPool(tokenPool).getTokenAddress();
        require(token != address(0), "NFTRouter: NOT_REGISTER_POOL");
        TransferHelper.safeTransferFrom(token, msg.sender, tokenPool, account);
        // IERC20(token).transferFrom(msg.sender, tokenPool, account);
        INFTPool(tokenPool).transferIntoNFT(nft, tokenId);
    }

    

    function getNFTMortgageInfo(address nft, uint256 tokenId) external view override returns (uint256) {
        address tokenPool = nftAddress[nft][tokenId];
        require(tokenPool != address(0), "NFTRouter: NOT_REGISTER_POOL");
        return INFTPool(tokenPool).getNFTMortgageInfo(nft, tokenId);
    }

    function mortgageNFT(address nft, uint256 tokenId, uint256 amount, uint256 timeReturn) external override {
        address tokenPool = nftAddress[nft][tokenId];
        // console.log(tokenPool, msg.sender);
        require(tokenPool != address(0), "NFTRouter: NOT_REGISTER_NFT");
        require(IERC721(nft).ownerOf(tokenId) == msg.sender, "NFTRouter: NOT_OWNER");
        emit PoolMortgage(msg.sender, tokenPool);
        IERC721(nft).transferFrom(msg.sender, tokenPool, tokenId);
        INFTPool(tokenPool).mortgageNFT(nft, tokenId, amount, msg.sender, timeReturn);
    }

    function redeemNFT(address nft, uint256 tokenId, uint256 amount) external override {
        address tokenPool = nftAddress[nft][tokenId];
        require(tokenPool != address(0), "NFTRouter: NOT_REGISTER_NFT");
        require(IERC721(nft).ownerOf(tokenId) == tokenPool, "NFTRouter: NOT_OWNER");
        address token = INFTPool(tokenPool).getTokenAddress();
        require(token != address(0), "NFTRouter: NOT_REGISTER_POOL");
        TransferHelper.safeTransferFrom(token, msg.sender, tokenPool, amount);
        INFTPool(tokenPool).redeemNFT(nft, tokenId, msg.sender);
    }

    function getNFTAddress(address nft, uint256 tokenId) external view returns (address) {
        return nftAddress[nft][tokenId];
    }
}