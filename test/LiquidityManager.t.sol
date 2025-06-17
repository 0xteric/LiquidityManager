// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/LiquidityManager.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LiquidityManagerTest is Test {
    LiquidityManager lm;
    address uniswapV2Router02 = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address uniswapV2Factory = 0xf1D7CC64Fb4452F05c498126312eBE29f30Fbcf9;
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address user = 0xF977814e90dA44bFA03b6295A0616a897441aceC;

    function setUp() public {
        lm = new LiquidityManager(uniswapV2Router02, uniswapV2Factory);
    }

    function testSwap() public {
        vm.startPrank(user);
        uint amountIn = 100 * 1e6;
        uint amountOutMin = 98 * 1e6;
        uint deadline = block.timestamp + 2 minutes;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = USDC;

        uint aBalanceBefore = IERC20(USDT).balanceOf(user);
        uint bBalanceBefore = IERC20(USDC).balanceOf(user);

        IERC20(USDT).approve(address(lm), amountIn);
        uint amountOut = lm.swapTokens(amountIn, amountOutMin, path, deadline);

        uint aBalanceAfter = IERC20(USDT).balanceOf(user);
        uint bBalanceAfter = IERC20(USDC).balanceOf(user);

        assertEq(aBalanceBefore, aBalanceAfter + amountIn);
        assertEq(bBalanceBefore + amountOut, bBalanceAfter);

        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(user);

        uint amountADesired = 111 * 1e6;
        uint amountBDesired = 111 * 1e6;
        uint deadline = block.timestamp + 2 minutes;

        uint aBalanceBefore = IERC20(USDT).balanceOf(user);
        uint bBalanceBefore = IERC20(USDC).balanceOf(user);

        IERC20(USDT).approve(address(lm), amountADesired);
        IERC20(USDC).approve(address(lm), amountBDesired);
        lm.addLiquidity(USDT, USDC, amountADesired, amountBDesired, (amountADesired * 98) / 100, (amountBDesired * 98) / 100, deadline);

        uint aBalanceAfter = IERC20(USDT).balanceOf(user);
        uint bBalanceAfter = IERC20(USDC).balanceOf(user);

        assertTrue(aBalanceAfter < aBalanceBefore);
        assertTrue(bBalanceAfter < bBalanceBefore);

        vm.stopPrank();
    }

    function testAddLiquiditySingleInput() public {
        vm.startPrank(user);

        uint amountIn = 111 * 1e6;
        uint amountOutMin = amountIn / 2 - 2 * 1e6;
        uint deadline = block.timestamp + 2 minutes;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = USDC;

        uint aBalanceBefore = IERC20(USDT).balanceOf(user);

        IERC20(USDT).approve(address(lm), amountIn);
        lm.addLiquiditySingleToken(path, amountIn, amountOutMin, ((amountIn / 2) * 98) / 100, (amountOutMin * 98) / 100, deadline);

        uint aBalanceAfter = IERC20(USDT).balanceOf(user);

        assertTrue(aBalanceAfter < aBalanceBefore);

        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        vm.startPrank(user);

        address tokenA = USDT;
        address tokenB = USDC;
        uint amountADesired = 100;
        uint amountBDesired = 100;
        uint amountAMin = (amountADesired * 98) / 100;
        uint amountBMin = (amountBDesired * 98) / 100;
        uint deadline = block.timestamp + 1 hours;

        address lp = IV2Factory(uniswapV2Factory).getPair(tokenA, tokenB);

        uint firstLpBalance = IERC20(lp).balanceOf(user);

        IERC20(tokenA).approve(address(lm), amountADesired);
        IERC20(tokenB).approve(address(lm), amountBDesired);

        uint liquidity = lm.addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, deadline);

        uint secondLpBalance = IERC20(lp).balanceOf(user);

        IERC20(lp).approve(address(lm), liquidity);

        lm.removeLiquidity(tokenA, tokenB, liquidity, 90, 90, deadline);

        uint finalLpBalance = IERC20(lp).balanceOf(user);

        assertEq(finalLpBalance, firstLpBalance);
        assertTrue(finalLpBalance < secondLpBalance);
    }
}
