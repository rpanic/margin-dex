pragma solidity ^0.6.8;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract LiquidityManager is Ownable{

    using SafeERC20 for IERC20;

    struct LiquidityPool{
        address token;
        uint256 totalAmount;
        uint256 amountLent;
        mapping(address => uint256) shares; //user -> amount tokens supplied
    }

    mapping(address => LiquidityPool) public pools;

    function supplyLiquidity(address _token, uint256 amount) public {

        LiquidityPool storage lp = pools[_token];
        require(lp.token != address(0), "Liquidity Pool not existent");
        IERC20 token = IERC20(_token);
        token.safeTransferFrom(msg.sender, address(this), amount);
        lp.totalAmount += amount;
        lp.shares[msg.sender] += amount;

    }

    function removeLiquidity(address _token, uint256 amount) public {
        
        LiquidityPool storage lp = pools[_token];
        require(lp.token != address(0), "Liquidity Pool not existent");
        require(lp.totalAmount - lp.amountLent >= amount, "LP has too much usage");
        require(lp.shares[msg.sender] >= amount, "Withdraw too much");

        lp.totalAmount -= amount;
        lp.shares[msg.sender] -= amount;
        IERC20 token = IERC20(_token);
        token.safeTransfer(msg.sender, amount);

    }

    function balanceOf(address _token, address user) public view returns (uint256 amount) {
        
        return (pools[_token].shares[user]);

    }

    function addPool(address _token) external onlyOwner {
        pools[_token].token = _token;
    }

}