//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Uniswap v3 interface
interface ISwapRouterV3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint256 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

/// @notice WETH9 interface
interface IWETH9Minimal {
    function deposit() external payable;
    function approve(address spender, uint256 value) external returns (bool);
}