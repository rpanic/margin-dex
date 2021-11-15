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
        address interestRateProvider;
        uint256 accInterestPerShare;
        mapping(address => uint256) rewardDebt; //user -> reward which user is not eligible to

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

        //Update rewardDebt
        lp.rewardDebt[msg.sender] += lp.accInterestPerShare * amount / 1 ether;

    }

    function removeLiquidity(address _token, uint256 amount) public {
        
        LiquidityPool storage lp = pools[_token];
        require(lp.token != address(0), "Liquidity Pool not existent");
        require(lp.totalAmount - lp.amountLent >= amount, "LP has too much usage");
        require(lp.shares[msg.sender] >= amount, "Withdraw too much");

        lp.totalAmount -= amount;
        lp.shares[msg.sender] -= amount;

        //Update RewardDebt
        lp.rewardDebt[msg.sender] -= lp.accInterestPerShare * amount / 1 ether;

        IERC20 token = IERC20(_token);
        token.safeTransfer(msg.sender, amount);

    }

    function withdrawInterest(address _token) public {
        LiquidityPool storage lp = pools[_token];
        require(lp.token != address(0), "Liquidity Pool not existent");
        uint256 interest = getPendingInterest(_token, msg.sender);
        lp.rewardDebt[msg.sender] = lp.shares[msg.sender] * lp.accInterestPerShare / 1 ether;
        
        IERC20(_token).transfer(msg.sender, interest);
    }
    
    function getPendingInterest(address _token, address addr) public view returns (uint256){
        LiquidityPool storage lp = pools[_token];
        return lp.shares[addr] * lp.accInterestPerShare / 1 ether - lp.rewardDebt[addr];
    }

    function balanceOf(address _token, address user) public view returns (uint256 amount) {
        
        return (pools[_token].shares[user]);

    }

    function addPool(address _token, address interestRateProvider) external onlyOwner {
        // require(IERC20(_token).decimals() == 18, "Decimals other than 18 not supported yet");
        pools[_token].token = _token;
        pools[_token].interestRateProvider = interestRateProvider;
    }

}