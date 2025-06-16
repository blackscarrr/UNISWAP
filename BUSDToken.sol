
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BUSDToken is ERC20 {
    address public owner;

    constructor(uint256 initialSupply) ERC20("Binance USD", "BUSD") {
        owner = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "BUSD: not owner");
        _mint(to, amount);
    }
}