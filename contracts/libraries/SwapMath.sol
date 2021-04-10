// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './FullMath.sol';
import './SqrtPriceMath.sol';

/// @title Computes the result of a swap within ticks
/// 计算给定区间内的交换函数
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// 如果amountSpecified大于0,feeAmount+amountIn <= amountRemaining
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// 当前开方价
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// 限定开方价,交易跨越tick时不能超过这个价格
    /// @param liquidity The usable liquidity
    /// 可用的流动性
    /// @param amountRemaining How much input or output amount is remaining to be swapped in/out
    /// 最多用来交换的数量,
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// 投入金额的费率,百分比
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// 交换结束后的开方价
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// 需要投入的token的数量,至于是token0还是token1,要开购买方向
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    /// 产出的token数量,至于是token0还是token1,要开购买方向
    /// @return feeAmount The amount of input that will be taken as a fee
    /// 投入部分中包含的手续费部分
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    )
        internal
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        // 交换方向,当前大于目标表示从右往左,表示卖token0买token1
        // 因为开方价=sqrt(t1/t0),向左表示t0变大t1变小
        bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
        // 大于等于0表示固定了投入量
        bool exactIn = amountRemaining >= 0;

        // 如果固定了投入量
        if (exactIn) {
            // 先估限定的去掉手续费后的投入量
            uint256 amountRemainingLessFee = FullMath.mulDiv(uint256(amountRemaining), 1e6 - feePips, 1e6);
            // 根据流动性和价格方向计算需要的投入量
            // SqrtPriceMath.getAmount0Delta指定的向上取整,防止精度攻击
            amountIn = zeroForOne
                ? SqrtPriceMath.getAmount0Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true)
                : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true);
            // 如果实际需要的投入量小于手续费后的限定量,说明直接买到了目标开方价了
            if (amountRemainingLessFee >= amountIn) sqrtRatioNextX96 = sqrtRatioTargetX96;
            else
                // 因为被投入量限定了,只能计算出可以买到哪个开发价
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    amountRemainingLessFee,
                    zeroForOne
                );
        } else {//固定了产出量
            // SqrtPriceMath.getAmount0Delta指定的向下取整,防止精度攻击
            amountOut = zeroForOne
                ? SqrtPriceMath.getAmount1Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, false)
                : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, false);
            // 如果期望产出量大于根据流动性计算出的可获得量,说明直接到了目标开发价了
            if (uint256(-amountRemaining) >= amountOut) sqrtRatioNextX96 = sqrtRatioTargetX96;
            else
                // 因为被产出量限定了,只能计算出可以买到哪个开发价
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    uint256(-amountRemaining),
                    zeroForOne
                );
        }

        // 是否达到了目标开方价
        bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

        // get the input/output amounts
        // 计算投入产出数量
        if (zeroForOne) {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount0Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, true);
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount1Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, false);
        } else {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, true);
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, false);
        }

        // cap the output amount to not exceed the remaining output amount
        // 如果产出大于了限定产出量,改
        if (!exactIn && amountOut > uint256(-amountRemaining)) {
            amountOut = uint256(-amountRemaining);
        }

        if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
            // we didn't reach the target, so take the remainder of the maximum input as fee
            // 因为达到了最大投入量,手续费计算就简单了
            feeAmount = uint256(amountRemaining) - amountIn;
        } else {
            // 根据设定的费率重新计算一次手续费
            feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
        }
    }
}
