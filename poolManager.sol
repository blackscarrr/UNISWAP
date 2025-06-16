// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./swapHook.sol";
import "./WETH.sol";

contract poolManager {
    struct pool {
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
        bool exists;
    }

    address public owner;
    swapHook public hook;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public  DAO = 0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413;
    address public wethToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    mapping (address => pool) public pools;

    modifier onlyOwner() {
        require(msg.sender == owner, "SwapManager: not owner");
        _;
        }

    modifier onlyHook() {
        require(msg.sender == address(hook), "SwapManager: not hook");
        _;
    }

    constructor(address _USDC, address _DAO, address _WETH, address _hook) {
        owner = msg.sender;
        USDC = _USDC;
        DAO = _DAO;
        wethToken = _WETH;
        hook = swapHook(_hook);
    }
}