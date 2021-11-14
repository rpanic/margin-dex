pragma solidity ^0.6.8;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract MockSwapProvider{

    mapping(address => uint256) prices;

    function setPrice(address addr, uint256 price) public {
        prices[addr] = price;
    }

    function swapOut(address assetIn, address assetOut, uint256 amountOut) public returns(uint256 amountIn){

        amountIn = 1 ether * amountOut / (1 ether * prices[assetIn] / prices[assetOut]);
        IERC20(assetIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(assetOut).transfer(msg.sender, amountOut);
        console.log("Swapped %s to %s", amountIn, amountOut);

    }

}