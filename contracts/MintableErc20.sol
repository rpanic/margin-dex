pragma solidity ^0.6.8;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MintableErc20 is ERC20{

    constructor(string memory name, string memory symbol) public ERC20(name, symbol){

    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }

}