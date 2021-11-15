pragma solidity ^0.6.8;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./LiquidityManager.sol";
import "./ISwapProvider.sol";
import "hardhat/console.sol";

contract TradingCore is LiquidityManager {

    using SafeERC20 for IERC20;

    struct Trade{
        uint256 positionSize; //Total Position Size (amount of asset1)
        address collateralAsset;
        uint256 amountCollateral;
        address assetAgainst;
        uint256 amountAgainst;
        uint256 timeOpened;
    }

    constructor(address _swapProvider) public {
        swapProvider = ISwapProvider(_swapProvider);
    }

    ISwapProvider swapProvider;

    uint256 tradeId = 0;

    mapping(uint256 => Trade) public trades;

    mapping(address => uint256[]) public userTrades;

    mapping(address => mapping(address => uint256)) public collateral; // User => Token => amount
    mapping(address => mapping(address => uint256)) public lockedCollateral;

    //TODO Limit asset so not any arbitrary token can be used
    function openTrade(address asset, address assetAgainst, uint256 amount, uint256 leverage) public {

        require(pairs[asset][assetAgainst].enabled > 0, "Pair not allowed");
        
        //TODO Make Approves better
        IERC20(assetAgainst).approve(address(swapProvider), ~uint256(0));

        require(leverage < 5, "Leverage too high");

        LiquidityPool storage lp = pools[assetAgainst];
        require(lp.token != address(0));

        uint256 requiredMarginAsset = amount * (leverage - 1);
        uint256 marginAsset2 = swapProvider.swapOut(assetAgainst, asset, requiredMarginAsset);
        require(lp.totalAmount - lp.amountLent >= marginAsset2, "Not enough collateral available");

        console.log("Borrowed %s of assetAgainst", marginAsset2);

        //Check that enough collateral is available
        require(collateral[msg.sender][asset] - lockedCollateral[msg.sender][asset] >= amount, "Not enough collateral given by user");
        lockedCollateral[msg.sender][asset] += amount;

        lp.amountLent += marginAsset2;
        uint256 id = tradeId;

        Trade storage trade = trades[id];
        trade.collateralAsset = asset;
        trade.amountCollateral = amount;
        trade.assetAgainst = assetAgainst;
        trade.amountAgainst = marginAsset2;
        trade.positionSize = requiredMarginAsset + amount;
        trade.timeOpened = block.timestamp;

        userTrades[msg.sender].push(id);

        tradeId++;

    }

    function closeTrade(uint256 id) public {

        Trade storage trade = trades[id];
        address collateralAsset = trade.collateralAsset;
        address assetAgainst = trade.assetAgainst;

        IERC20(collateralAsset).approve(address(swapProvider), ~uint256(0));
        uint256 amountIn = swapProvider.swapOut(collateralAsset, assetAgainst, trade.amountAgainst);

        console.log("Payed back %s of assetAgainst with %s of asset1", trade.amountAgainst, amountIn);

        //Pay back LP
        LiquidityPool storage lp = pools[assetAgainst];
        require(lp.token != address(0)); //TODO needed?
        lp.amountLent -= trade.amountAgainst;

        //Give User rest of the funds
        lockedCollateral[msg.sender][collateralAsset] -= trade.amountCollateral;
        uint256 sub = amountIn + trade.amountCollateral;
        if(trade.positionSize > sub){
            collateral[msg.sender][collateralAsset] += (trade.positionSize - sub);
        }else{
            collateral[msg.sender][collateralAsset] -= (sub - trade.positionSize);
        }

    }

    function liquidate(uint256 id) public {



        //TODO
    }

    function addCollateral(address asset, uint256 amount) public {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        collateral[msg.sender][asset] += amount;
    }
    
    function removeCollateral(address asset, uint256 amount) public {
        //Check if Collateral can be withdrawn
        uint256 col = collateral[msg.sender][asset];
        uint256 locked = lockedCollateral[msg.sender][asset];
        require(locked <= col, "Overflow");
        require(col - locked >= amount, "Not enough collateral withdrawable");

        collateral[msg.sender][asset] -= amount;
        IERC20(asset).safeTransfer(msg.sender, amount);
    }

    //Pair Logic

    struct Pair{
        //Require: asset1 < asset2
        // address asset1;
        // address asset2;
        uint128 provision;
        uint128 enabled;   //Should safe 1 Storage slot
        address swapProvider;
    }

    mapping(address => mapping(address => Pair)) public pairs;

    function updatePair(address asset1, address asset2, uint128 provision, address _swapProvider) public onlyOwner {
        require(asset1 < asset2, "Tokens unordered");
        Pair storage p = pairs[asset1][asset2];
        // p.asset1 = asset1;
        // p.asset2 = asset2;
        p.provision = provision;
        p.enabled = 1;
        p.swapProvider = _swapProvider;
    }

    function removePair(address asset1, address asset2) public onlyOwner {
        pairs[asset1][asset2].enabled = 0;
    }

    // modifier pairEnabled(address asset1, address asset2) {
    //     require(pairs[asset1][asset2].enabled > 0, "Pair not allowed");
    //     _;
    // }

}