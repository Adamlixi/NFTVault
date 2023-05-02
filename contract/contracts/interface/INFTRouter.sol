// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFTRouter {
    function transferIntoNFT(address nft, uint256 tokenId, uint256 account) external;
    function registerNFT(address nft, uint256 tokenId, address token) external;
    function GetNFTMortgageInfo(address nft, uint256 tokenId) external view returns (uint256);
    function mortgageNFT(address nft, uint256 tokenId, uint256 amount, address token, uint256 timeReturn) external;
    function redeemNFT(address nft, uint256 tokenId, uint256 amount) external;
}