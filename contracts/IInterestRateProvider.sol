pragma solidity ^0.6.8;

// SPDX-License-Identifier: MIT

interface IInterestRateProvider{
    
    /**
        @param reserves Total of Reserves of asset
        @param utilized The portion of the Reserves which is utilized
        @return interestRate Current Interest Rate in wei (1e18 == 100%)
     */
    function getInterestRate(uint256 reserves, uint256 utilized) external view returns (uint256 interestRate);

}