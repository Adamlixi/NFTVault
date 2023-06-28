// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFTPoolFactory {
    function createPool(address token, address auction) external returns (address pool);
    function setFeeTo(address _feeTo) external;
    function setFeeToSetter(address _feeToSetter) external;
    function getPoolByToken(address token) external view returns (address);
}