// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFTPoolFactory {
    function createPool(address token) external returns (address pool);
    function setFeeTo(address _feeTo) external;
    function setFeeToSetter(address _feeToSetter) external;
}