// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFTToken {
    function updateMoneyInNFT(int tokenCounts) external;
    function registerMint(uint256 count) external;
}