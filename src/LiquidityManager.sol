// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./interfaces/IV2Router02.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract LiquidityManager {
    using SafeERC20 for IERC20;
    address public V2Router02;

    event Swap(address tokenIn, address tokenOut, uint amountIn, uint amountOut);
    event AddLiquidity(address tokenA, address tokenB, uint lpAmount);

    constructor(address _V2router02) {
        V2Router02 = _V2router02;
    }

    function swapTokens(uint amountIn, uint amountOutMin, address[] memory path, uint deadline) public returns (uint) {
        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(V2Router02, amountIn);
        uint[] memory amounts = IV2Router02(V2Router02).swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, deadline);

        emit Swap(path[0], path[path.length - 1], amountIn, amounts[amounts.length - 1]);

        return amounts[amounts.length - 1];
    }

    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, uint deadline) public returns (uint) {
        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountBDesired);

        IERC20(tokenA).approve(V2Router02, amountADesired);
        IERC20(tokenB).approve(V2Router02, amountBDesired);

        (, , uint liquidity) = IV2Router02(V2Router02).addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, msg.sender, deadline);
        emit AddLiquidity(tokenA, tokenB, liquidity);
        return liquidity;
    }

    function addLiquiditySingleToken(address[] memory path, uint amountIn, uint amountOutMin, uint amountAMin, uint amountBMin, uint deadline) public returns (uint) {
        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(V2Router02, amountIn);

        uint[] memory amounts = IV2Router02(V2Router02).swapExactTokensForTokens(amountIn / 2, amountOutMin, path, address(this), deadline);

        emit Swap(path[0], path[path.length - 1], amountIn, amounts[amounts.length - 1]);

        IERC20(path[0]).approve(V2Router02, amountIn / 2);
        IERC20(path[1]).approve(V2Router02, amounts[amounts.length - 1]);

        (, , uint liquidity) = IV2Router02(V2Router02).addLiquidity(path[0], path[1], amountIn / 2, amounts[amounts.length - 1], amountAMin, amountBMin, msg.sender, deadline);

        emit AddLiquidity(path[0], path[1], liquidity);
        return liquidity;
    }
}
