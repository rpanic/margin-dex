pragma solidity ^0.6.8;

// SPDX-License-Identifier: MIT

import "./IInterestRateProvider.sol";

contract LinearKinkInterestRateProvider is IInterestRateProvider {

    uint256 kink = 0.8 ether;
    uint256 k_beforeKink = 0.1 ether; // = x / 100 where x is desired point at 100% utilization
    uint256 k_afterKink = 1 ether;

    function getInterestRate(uint256 reserves, uint256 utilized) public override view returns (uint256 interestRate){

        uint256 utilization = utilized * 1e18 / reserves;
        require(utilization <= 1e18, "Utilization greater than 100%");
        return rateByUtilization(utilization);

    }

    function rateByUtilization(uint256 utilization) internal view returns (uint256){

        if(utilization <= kink){
            return utilization * k_beforeKink / 1e18;
        }else{
            return (kink * k_beforeKink + ((utilization - kink) * k_afterKink)) / 1e18;
        }

    }

}