// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFTPool {
    function initialize(address _token, address _bank)  external;
    function transferIntoNFT(address nft, uint256 tokenId) external;
    function registerNFT(address nft, uint256 tokenId) external;
    function getNFTMortgageInfo(address nft, uint256 tokenId) external view returns (uint256);
    function checkLiquidateNFTPrice(address nft, uint256 tokenId) external view returns (uint256);
    function checkNFTStatus(address nft, uint256 tokenId) external view returns (int);
    function getTokenAddress() external view returns (address);
    function mortgageNFT(address nft, uint256 tokenId, uint256 amount, address to, uint256 timeReturn) external;
    function redeemNFT(address nft, uint256 tokenId, address to) external;
}