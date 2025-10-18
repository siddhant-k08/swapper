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

/**
    @title ETH -> USDT Uniswap V3 Swap
    @notice Single-function contract: accepts native ETH, swaps for USDT via UniSwap v3, sends USDT to msg.sender
 */
contract USDTSwapper {
    ISwapRouterV3 public immutable swapRouter;
    address public immutable WETH9;
    address public immutable USDT;
    uint24 public immutable poolFee;

    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut);

    constructor(address _swapRouter, address _weth9, address _usdt, uint256 _poolFee) {
        require(
            _swapRouter != address(0) && _weth9 != address(0) && _usdt != address(0), "ZERO_ADDRESS"
        );
        swapRouter = ISwapRouterV3(_swapRouter);
        WETH9 = _weth9;
        USDT = _usdt;
        poolFee = _poolFee; // e.g. 500, 3000, or 10000

        // one-time approval to save gas
        require(IWETH9Minimal(WETH9).approve(address(swapRouter), type(uint256).max), "APPROVE_INIT_FAILED");
    }

    /// @notice Swap ETH for USDT and send USDT to msg.sender
    /// @param minUSDTOut Minimum USDT expected
    /// @return amountOut The amount of DAI received
    function swapExactETHForUSDT(uint256 minUSDTOut) external payable returns (uint256 amountOut) {
        amountOut = _swapExactETHForUSDTTo(msg.sender, msg.value, minUSDTOut);
    }

    /// @dev Internal helper used by both the explicit function and the receive() handler
    function _swapExactETHForUSDTTo(address recipient, uint256 amountIn, uint256 minOut) internal returns(uint256 amountOut) {
        require(amountIn > 0, "NO_ETH");
        IWETH9Minimal(WETH9).deposit{value: amountIn}();
        amountOut = swapRouter.exactInputSingle(
            ISwapRouterV3.ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: USDT,
                fee: poolFee,
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum; minOut,
                sqrtPriceLimitX96: 0
            })
        );
        
        emit Swap(recipient, amountIn, amountOut);
    }

    /// @notice Auto-swap on plain ETH receives and send USDT back to msg.sender
    recieve() external payable {
        if (msg.value == 0) return;
        _swapExactETHForUSDTTo(msg.sender, msg.value, 0);
    }
}