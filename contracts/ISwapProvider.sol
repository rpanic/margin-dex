pragma solidity ^0.6.8;

// SPDX-License-Identifier: MIT

interface ISwapProvider{
    //TODO Think about fees!
    // function swap(address assetIn, address assetOut, uint256 amountIn) external returns(uint256 amountOut);
    function swapOut(address assetIn, address assetOut, uint256 amountOut) external returns(uint256 amountIn);
    // function getAmountOut(address assetIn, address assetOut, uint256 amountIn) external view returns(uint256 amountOut);
}