// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './libraries/TransferHelper.sol';
import './interface/INFTRouter.sol';
import './interface/IERC20.sol';
import './interface/INFTPool.sol';
import './interface/IERC721.sol';
import './interface/INFTPoolFactory.sol';


contract NFTRouter is INFTRouter {
    address public factory; //工厂地址
    mapping(address => mapping (uint256 => address)) public nftAddress;

    function transferIntoNFT(address nft, uint256 tokenId, uint256 account) external override {
        address tokenPool = nftAddress[nft][tokenId];
        require(tokenPool != address(0), "NFTRouter: NFT_POOL_NOT_CREATED");
        require(IERC721(nft).ownerOf(tokenId) == msg.sender, "NFTRouter: NOT_OWNER");
        address token = INFTPool(tokenPool).GetTokenAddress()
        require(token != address(0), "NFTRouter: NOT_REGISTER_POOL");
        TransferHelper(token).safeTransferFrom(msg.sender, tokenPool, account);
        INFTPool(tokenPool).transferIntoNFT(nft, tokenId);
    }

    function registerNFT(address nft, uint256 tokenId, address token) external override {
        require(IERC721(nft).ownerOf(tokenId) == msg.sender, "NFTRouter: NOT_OWNER");
        require(nftAddress[nft][tokenId] == address(0), "NFTRouter: NFT_REGISTERED");
        address tokenPool = INFTPoolFactory(factory).getPoolByToken(token);
        require(tokenPool != address(0), "NFTRouter: NOT_REGISTER_POOL");
        INFTPool(tokenPool).registerNFT(nft, tokenId);
        nftAddress[nft][tokenId] = token;
    }

    function GetNFTMortgageInfo(address nft, uint256 tokenId) external view override returns (uint256) {
        address tokenPool = nftAddress[nft][tokenId];
        require(tokenPool != address(0), "NFTRouter: NOT_REGISTER_POOL");
        return INFTPool(tokenPool).GetNFTMortgageInfo(nft, tokenId);
    }

    function mortgageNFT(address nft, uint256 tokenId, uint256 amount, uint256 timeReturn) external override {
        address tokenPool = nftAddress[nft][tokenId];
        require(tokenPool != address(0), "NFTRouter: NOT_REGISTER_NFT");
        require(IERC721(nft).ownerOf(tokenId) == msg.sender, "NFTRouter: NOT_OWNER");
        IERC721(nft).transferFrom(msg.sender, tokenPool, tokenId);
        INFTPool(tokenPool).mortgageNFT(nft, tokenId, amount, msg.sender, timeReturn);
    }

    function redeemNFT(address nft, uint256 tokenId, uint256 amount) external override {
        address tokenPool = nftAddress[nft][tokenId];
        require(tokenPool != address(0), "NFTRouter: NOT_REGISTER_NFT");
        require(IERC721(nft).ownerOf(tokenId) == tokenPool, "NFTRouter: NOT_OWNER");
        address token = INFTPool(tokenPool).GetTokenAddress()
        require(token != address(0), "NFTRouter: NOT_REGISTER_POOL");
        TransferHelper(token).safeTransferFrom(token, msg.sender, tokenPool, amount);
        INFTPool(tokenPool).redeemNFT(nft, tokenId, msg.sender);
    }

    function GetNFTAddress(address nft, uint256 tokenId) external view returns (address) {
        return nftAddress[nft][tokenId];
    }
}