// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DAO.sol";
import "./WETH.sol";
import "./BUSDToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

contract swapHook {
    address public owner;
    address public swapManager; 
    BUSDToken public busd;       
    AggregatorV3Interface public priceFeedBNB; 
    AggregatorV3Interface public priceFeedETH;

    mapping(bytes32 => uint256) public feeBasisPoints;
    mapping(address => uint256) public userVolumeUSD;
    uint256 public constant THRESHOLD_USDC = 2000 * (10**6);

    modifier onlyOwner() {
    require(msg.sender == owner, "SwapHook: not owner");
    _;
    }

        modifier onlyManager() {
        require(msg.sender == swapManager, "SwapHook: not manager");
        _;
    }

    constructor(address _busdToken, address _bnbFeed, address _ethFeed) {
        owner = msg.sender;
        busd = BUSDToken(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
        priceFeedBNB = AggregatorV3Interface(_bnbFeed);
        priceFeedETH = AggregatorV3Interface(_ethFeed);
    }

    function setSwapManager(address _manager) external onlyOwner {
        swapManager = _manager;
    }

    function setFee(address tokenA, address tokenB, uint256 feeBps) external onlyOwner {
        require(feeBps >= 1000, "Fee too high");
        bytes32 pid = tokenA < tokenB 
            ? keccak256(abi.encodePacked(tokenA, tokenB))
            : keccak256(abi.encodePacked(tokenB, tokenA));
        feeBasisPoints[pid] = feeBps;
    }

    function getFee(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256) {
        bytes32 pid = tokenIn < tokenOut 
            ? keccak256(abi.encodePacked(tokenIn, tokenOut))
            : keccak256(abi.encodePacked(tokenOut, tokenIn));
        uint256 feeBps = feeBasisPoints[pid];
        return (amountIn * feeBps) / 10000;
    }

    function recordSwap(address user, address tokenIn, address tokenOut, uint256 amountIn) external onlyManager {
        uint256 valueUSD;

        if (tokenIn == swapManager) {
                return;
            }

        if (tokenIn == swapManager) {
                valueUSD = 0;
            }

        if (tokenIn == address(0)) {
                valueUSD = 0;
            }

        else if (tokenIn == address(busd)) {
                valueUSD = amountIn / 1e12;
            }
        else if (IERC20Extended(tokenIn).decimals() == 18) {
            (, int ethPrice,,,) = priceFeedETH.latestRoundData();
            require(ethPrice > 0, "ETH price error");
            uint256 price = uint256(ethPrice);
            uint256 usd18 = (amountIn * price) / (10**8);
            valueUSD = usd18 / (10**12);
        }

        else {
            valueUSD = amountIn;
        }

        userVolumeUSD[user] += valueUSD;
    
        while (userVolumeUSD[user] >= THRESHOLD_USDC) {
            userVolumeUSD[user] -= THRESHOLD_USDC;
            _rewardUser(user);
        }

    }
    
    function _rewardUser(address user) internal {
        (, int priceBNB,,,) = priceFeedBNB.latestRoundData();
        require(priceBNB > 0, "BNB price error");
        uint8 dec = priceFeedBNB.decimals();
        uint256 rewardAmount = (uint256(priceBNB) * 15 * 10**18) / (1000 * (10**dec));
        busd.transfer(user, rewardAmount);
    }
}